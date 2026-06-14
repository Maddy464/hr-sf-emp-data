'use strict';

const cds = require('@sap/cds');

const Status = {
  Pending:  'PENDING',
  Approved: 'APPROVED',
  Rejected: 'REJECTED',
};

module.exports = class WorkflowCallbackService extends cds.ApplicationService {

  async init() {
    // All DB writes go directly to the DB entity — no service auth layer to
    // cross, and the actionBy value comes from SBPA's payload (not $user).
    const db = await cds.connect.to('db');

    // ── approveLeave ──────────────────────────────────────────────────────────
    this.on('approveLeave', async (req) => {
      const { leaveRequestId, workflowInstanceId, actionBy, comments } = req.data;

      const request = await db.run(
        SELECT.one.from('sap.hr.LeaveRequests')
          .columns('ID', 'status', 'employee_employeeId', 'leaveType_code',
                   'startDate', 'numberOfDays')
          .where({ ID: leaveRequestId })
      );

      if (!request)
        return req.error(404, `Leave request ${leaveRequestId} not found`);
      if (request.status !== Status.Pending)
        return req.error(400,
          `Only Pending requests can be approved (current: ${request.status})`);

      const now  = new Date().toISOString();
      const days = _num(request.numberOfDays);
      const year = new Date(request.startDate).getFullYear();

      await db.run(
        UPDATE('sap.hr.LeaveRequests').set({
          status:             Status.Approved,
          approvedBy:         actionBy,
          approvedAt:         now,
          managerComments:    comments ?? null,
          workflowInstanceId: workflowInstanceId ?? null,
        }).where({ ID: leaveRequestId })
      );

      await _shiftBalance(db,
        request.employee_employeeId, request.leaveType_code, year,
        { pendingDelta: -days, usedDelta: +days }
      );

      await db.run(
        INSERT.into('sap.hr.ApprovalHistory').entries({
          ID:         cds.utils.uuid(),
          request_ID: leaveRequestId,
          action:     'APPROVED',
          actionBy,
          actionAt:   now,
          comments:   comments ?? null,
          fromStatus: Status.Pending,
          toStatus:   Status.Approved,
        })
      );

      return { status: 'APPROVED', message: `Leave request approved by ${actionBy}` };
    });

    // ── rejectLeave ───────────────────────────────────────────────────────────
    this.on('rejectLeave', async (req) => {
      const { leaveRequestId, workflowInstanceId, actionBy, reason } = req.data;

      const request = await db.run(
        SELECT.one.from('sap.hr.LeaveRequests')
          .columns('ID', 'status', 'employee_employeeId', 'leaveType_code',
                   'startDate', 'numberOfDays')
          .where({ ID: leaveRequestId })
      );

      if (!request)
        return req.error(404, `Leave request ${leaveRequestId} not found`);
      if (request.status !== Status.Pending)
        return req.error(400,
          `Only Pending requests can be rejected (current: ${request.status})`);

      const now  = new Date().toISOString();
      const days = _num(request.numberOfDays);
      const year = new Date(request.startDate).getFullYear();

      await db.run(
        UPDATE('sap.hr.LeaveRequests').set({
          status:             Status.Rejected,
          rejectedBy:         actionBy,
          rejectedAt:         now,
          rejectionReason:    reason,
          workflowInstanceId: workflowInstanceId ?? null,
        }).where({ ID: leaveRequestId })
      );

      await _shiftBalance(db,
        request.employee_employeeId, request.leaveType_code, year,
        { pendingDelta: -days }
      );

      await db.run(
        INSERT.into('sap.hr.ApprovalHistory').entries({
          ID:         cds.utils.uuid(),
          request_ID: leaveRequestId,
          action:     'REJECTED',
          actionBy,
          actionAt:   now,
          comments:   reason,
          fromStatus: Status.Pending,
          toStatus:   Status.Rejected,
        })
      );

      return { status: 'REJECTED', message: `Leave request rejected by ${actionBy}` };
    });

    await super.init();
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

const _num = v => parseFloat(v) || 0;

// Adjust pending / used counters and recalculate remaining.
async function _shiftBalance(db, employeeId, leaveTypeCode, year,
                             { pendingDelta = 0, usedDelta = 0 }) {
  const bal = await db.run(
    SELECT.one.from('sap.hr.LeaveBalances').where({
      employee_employeeId: employeeId,
      leaveType_code:      leaveTypeCode,
      fiscalYear:          year,
    })
  );
  if (!bal) return;

  const newPending   = Math.max(_num(bal.pending) + pendingDelta, 0);
  const newUsed      = Math.max(_num(bal.used)    + usedDelta,    0);
  const newRemaining = Math.max(
    _num(bal.allocated) + _num(bal.carryForward) - newUsed - newPending, 0
  );

  await db.run(
    UPDATE('sap.hr.LeaveBalances')
      .set({ pending: newPending, used: newUsed, remaining: newRemaining })
      .where({ ID: bal.ID })
  );
}
