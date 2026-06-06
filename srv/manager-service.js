'use strict';

const cds = require('@sap/cds');

const Status = {
  Draft:     'DRAFT',
  Pending:   'PENDING',
  Approved:  'APPROVED',
  Rejected:  'REJECTED',
  Cancelled: 'CANCELLED',
  Withdrawn: 'WITHDRAWN',
};

const HistoryAction = {
  Approved:  'APPROVED',
  Rejected:  'REJECTED',
  Cancelled: 'CANCELLED',
};

module.exports = class ManagerService extends cds.ApplicationService {

  async init() {
    const { TeamRequests, ApprovalHistory, Employees } = this.entities;

    // Balance mutations bypass ManagerService auth (TeamLeaveBalances has a
    // restrictive WHERE clause). Access the DB entity directly instead.
    const db = await cds.connect.to('db');

    // ── After READ: set per-action flags based on request status ─────────────
    this.after('READ', TeamRequests, (data) => {
      const rows = Array.isArray(data) ? data : [data];
      rows.forEach(r => {
        if (!r) return;
        r.criticality    = r.status === Status.Approved ? 3
                         : r.status === Status.Pending  ? 2
                         : r.status === Status.Rejected ? 1
                         : 0;
        r.approveEnabled = r.status === Status.Pending;
        r.rejectEnabled  = r.status === Status.Pending;
        r.cancelEnabled  = r.status === Status.Draft || r.status === Status.Pending;
      });
    });

    // ── approve ───────────────────────────────────────────────────────────────
    this.on('approve', TeamRequests, async (req) => {
      const { ID }      = req.params[0];
      const { comments } = req.data;

      const request = await SELECT.one.from(TeamRequests)
        .columns('ID', 'status', 'employee_employeeId', 'leaveType_code',
                 'startDate', 'numberOfDays', 'requestManager_employeeId')
        .where({ ID });

      if (!request)
        return req.error(404, `Leave request ${ID} not found`);
      if (request.status !== Status.Pending)
        return req.error(400, `Only Pending requests can be approved (current: ${request.status})`);

      await _assertIsDesignatedManager(req, Employees, request.requestManager_employeeId);
      if (req.errors?.length) return;

      const now  = new Date().toISOString();
      const days = _num(request.numberOfDays);

      await UPDATE(TeamRequests).set({
        status:          Status.Approved,
        approvedBy:      req.user.id,
        approvedAt:      now,
        managerComments: comments ?? null,
      }).where({ ID });

      const year = new Date(request.startDate).getFullYear();
      await _shiftBalance(db,
        request.employee_employeeId, request.leaveType_code, year,
        { pendingDelta: -days, usedDelta: +days }
      );

      await _logHistory(ApprovalHistory, {
        request_ID: ID,
        action:     HistoryAction.Approved,
        actionBy:   req.user.id,
        actionAt:   now,
        comments:   comments ?? null,
        fromStatus: Status.Pending,
        toStatus:   Status.Approved,
      });

      return SELECT.one.from(TeamRequests).where({ ID });
    });

    // ── rejectRequest ─────────────────────────────────────────────────────────
    this.on('rejectRequest', TeamRequests, async (req) => {
      const { ID }    = req.params[0];
      const { reason } = req.data;

      const request = await SELECT.one.from(TeamRequests)
        .columns('ID', 'status', 'employee_employeeId', 'leaveType_code',
                 'startDate', 'numberOfDays', 'requestManager_employeeId')
        .where({ ID });

      if (!request)
        return req.error(404, `Leave request ${ID} not found`);
      if (request.status !== Status.Pending)
        return req.error(400, `Only Pending requests can be rejected (current: ${request.status})`);

      await _assertIsDesignatedManager(req, Employees, request.requestManager_employeeId);
      if (req.errors?.length) return;

      const now  = new Date().toISOString();
      const days = _num(request.numberOfDays);

      await UPDATE(TeamRequests).set({
        status:          Status.Rejected,
        rejectedBy:      req.user.id,
        rejectedAt:      now,
        rejectionReason: reason,
      }).where({ ID });

      const year = new Date(request.startDate).getFullYear();
      await _shiftBalance(db,
        request.employee_employeeId, request.leaveType_code, year,
        { pendingDelta: -days }
      );

      await _logHistory(ApprovalHistory, {
        request_ID: ID,
        action:     HistoryAction.Rejected,
        actionBy:   req.user.id,
        actionAt:   now,
        comments:   reason,
        fromStatus: Status.Pending,
        toStatus:   Status.Rejected,
      });

      return SELECT.one.from(TeamRequests).where({ ID });
    });

    // ── cancel ────────────────────────────────────────────────────────────────
    this.on('cancel', TeamRequests, async (req) => {
      const { ID }    = req.params[0];
      const { reason } = req.data;

      const request = await SELECT.one.from(TeamRequests)
        .columns('ID', 'status', 'employee_employeeId', 'leaveType_code',
                 'startDate', 'numberOfDays', 'requestManager_employeeId')
        .where({ ID });

      if (!request)
        return req.error(404, `Leave request ${ID} not found`);
      if (![Status.Draft, Status.Pending].includes(request.status))
        return req.error(400,
          `Only Draft or Pending requests can be cancelled (current: ${request.status})`);

      await _assertIsDesignatedManager(req, Employees, request.requestManager_employeeId);
      if (req.errors?.length) return;

      const now  = new Date().toISOString();
      const days = _num(request.numberOfDays);

      await UPDATE(TeamRequests).set({
        status:             Status.Cancelled,
        cancelledBy:        req.user.id,
        cancelledAt:        now,
        cancellationReason: reason ?? null,
      }).where({ ID });

      if (request.status === Status.Pending) {
        const year = new Date(request.startDate).getFullYear();
        await _shiftBalance(db,
          request.employee_employeeId, request.leaveType_code, year,
          { pendingDelta: -days }
        );
      }

      await _logHistory(ApprovalHistory, {
        request_ID: ID,
        action:     HistoryAction.Cancelled,
        actionBy:   req.user.id,
        actionAt:   now,
        comments:   reason ?? null,
        fromStatus: request.status,
        toStatus:   Status.Cancelled,
      });

      return SELECT.one.from(TeamRequests).where({ ID });
    });

    await super.init();
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

// HANA's hdb driver returns Decimal columns as strings (e.g. "5.00"), not numbers.
// Always convert through _num() before arithmetic to avoid "Wrong input for DECIMAL type".
const _num = v => parseFloat(v) || 0;

// Verify the logged-in user is the designated approving manager for this request.
async function _assertIsDesignatedManager(req, Employees, requestManagerEmployeeId) {
  if (!requestManagerEmployeeId) {
    req.error(403, 'No approving manager designated for this request');
    return;
  }
  const mgr = await SELECT.one.from(Employees)
    .columns('userId')
    .where({ employeeId: requestManagerEmployeeId });
  if (!mgr || mgr.userId !== req.user.id) {
    req.error(403, 'Only the designated approving manager can act on this request');
  }
}

// Adjust pending / used counters and recalculate remaining.
// Uses cds.db directly so TeamLeaveBalances WHERE restriction doesn't block it.
async function _shiftBalance(db, employeeId, leaveTypeCode, year, { pendingDelta = 0, usedDelta = 0 }) {
  const bal = await db.run(
    SELECT.one.from('sap.hr.LeaveBalances').where({
      employee_employeeId: employeeId,
      leaveType_code:      leaveTypeCode,
      fiscalYear:          year,
    })
  );
  if (!bal) return;

  const newPending   = Math.max(_num(bal.pending)   + pendingDelta, 0);
  const newUsed      = Math.max(_num(bal.used)      + usedDelta,    0);
  const newRemaining = Math.max(
    _num(bal.allocated) + _num(bal.carryForward) - newUsed - newPending,
    0
  );

  await db.run(
    UPDATE('sap.hr.LeaveBalances')
      .set({ pending: newPending, used: newUsed, remaining: newRemaining })
      .where({ ID: bal.ID })
  );
}

// Append an entry to the approval history log.
async function _logHistory(ApprovalHistory, entry) {
  await INSERT.into(ApprovalHistory).entries({
    ID: cds.utils.uuid(),
    ...entry,
  });
}
