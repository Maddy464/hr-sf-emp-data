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

const Action = {
  Submitted: 'SUBMITTED',
  Approved:  'APPROVED',
  Rejected:  'REJECTED',
  Cancelled: 'CANCELLED',
  Withdrawn: 'WITHDRAWN',
  Modified:  'MODIFIED',
};

module.exports = class LeaveService extends cds.ApplicationService {

  async init() {
    const { LeaveRequests, ApprovalHistory, Employees } = this.entities;
    // LeaveBalances is exposed as MyLeaveBalances in LeaveService (with a user-scoped
    // @restrict).  Balance mutations in action handlers must bypass that restriction
    // and touch any employee's balance, so we use the underlying DB entity directly.
    const LeaveBalances = 'sap.hr.LeaveBalances';

    // Draft entity — non-enumerable in this.entities, resolved via model.definitions.
    // Handlers registered here fire during draft CREATE/PATCH/READ.
    const LeaveRequestDrafts =
      this.model.definitions['LeaveService.LeaveRequests.drafts'];
    const _allTargets = LeaveRequestDrafts
      ? [LeaveRequestDrafts, LeaveRequests]
      : [LeaveRequests];

    // ── After READ: virtual flags + back-fill draft projected fields ──────────
    // Core.OperationAvailable uses a simple path (false → HIDDEN on Object Page,
    // DISABLED on LineItem toolbar).
    // CAP does not JOIN the Employees table when reading the draft entity, so
    // employeeName and department are null in the draft form. Back-fill them with
    // a single batched SELECT so the create form shows correct values immediately.
    const _afterRead = async (data, req) => {
      const isMgr = req.user.is('Manager') || req.user.is('HRAdmin');
      const rows  = Array.isArray(data) ? data : [data];

      const missingEmp = rows.filter(r => r?.employee_employeeId && !r.employeeName);
      if (missingEmp.length) {
        const ids  = [...new Set(missingEmp.map(r => r.employee_employeeId))];
        const emps = await SELECT.from(Employees)
          .columns('employeeId', 'fullName', 'department')
          .where({ employeeId: { in: ids } });
        const byId = Object.fromEntries(emps.map(e => [e.employeeId, e]));
        for (const r of missingEmp) {
          const e = byId[r.employee_employeeId];
          if (e) { r.employeeName = e.fullName; r.department = e.department; }
        }
      }

      const missingMgr = rows.filter(r => r?.requestManager_employeeId && !r.requestManagerName);
      if (missingMgr.length) {
        const ids = [...new Set(missingMgr.map(r => r.requestManager_employeeId))];
        const mgrs = await SELECT.from(Employees)
          .columns('employeeId', 'fullName')
          .where({ employeeId: { in: ids } });
        const byId = Object.fromEntries(mgrs.map(m => [m.employeeId, m]));
        for (const r of missingMgr) {
          const m = byId[r.requestManager_employeeId];
          if (m) r.requestManagerName = m.fullName;
        }
      }

      rows.forEach(r => {
        if (!r) return;
        r.criticality     = r.status === Status.Approved ? 3
                          : r.status === Status.Pending  ? 2
                          : r.status === Status.Rejected ? 1
                          : 0;
        r.submitEnabled   = r.status === Status.Draft;
        r.approveEnabled  = isMgr && r.status === Status.Pending;
        r.rejectEnabled   = isMgr && r.status === Status.Pending;
        r.cancelEnabled   = isMgr && (r.status === Status.Draft || r.status === Status.Pending);
        r.withdrawEnabled = r.status === Status.Approved;
      });
    };
    for (const t of _allTargets) this.after('READ', t, _afterRead);

    // ── submit ──────────────────────────────────────────────────────────────
    this.on('submit', LeaveRequests, async (req) => {
      const { ID } = req.params[0];
      const { notes } = req.data;

      const request = await SELECT.one.from(LeaveRequests)
        .columns('*', 'leaveType_code', 'employee_employeeId',
                 'startDate', 'endDate', 'numberOfDays', 'status')
        .where({ ID });

      if (!request) return req.error(404, `Leave request ${ID} not found`);
      if (request.status !== Status.Draft)
        return req.error(400, `Only Draft requests can be submitted (current: ${request.status})`);

      _validateDates(req, request.startDate, request.endDate);
      if (req.errors?.length) return;

      const days = _num(request.numberOfDays)
        || _calcWorkingDays(request.startDate, request.endDate,
                            request.halfDayStart, request.halfDayEnd);

      // Balance check
      const balance = await _getBalance(
        LeaveBalances, request.employee_employeeId,
        request.leaveType_code, new Date(request.startDate).getFullYear()
      );
      if (balance && balance.remaining < days) {
        req.warn(400,
          `Insufficient balance: ${balance.remaining} days available, ${days} requested`
        );
      }

      const now = new Date().toISOString();

      await UPDATE(LeaveRequests).set({
        status:      Status.Pending,
        submittedAt: now,
        numberOfDays: days,
        ...(notes ? { requestNotes: notes } : {}),
      }).where({ ID });

      await _logHistory(ApprovalHistory, {
        request_ID: ID,
        action:     Action.Submitted,
        actionBy:   req.user.id,
        actionAt:   now,
        comments:   notes,
        fromStatus: Status.Draft,
        toStatus:   Status.Pending,
      });

      await _updatePending(LeaveBalances, request.employee_employeeId,
                           request.leaveType_code,
                           new Date(request.startDate).getFullYear(), days, '+');

      return SELECT.one.from(LeaveRequests).where({ ID });
    });

    // ── approve ─────────────────────────────────────────────────────────────
    this.on('approve', LeaveRequests, async (req) => {
      const { ID } = req.params[0];
      const { comments } = req.data;

      const request = await SELECT.one.from(LeaveRequests)
        .columns('*', 'leaveType_code', 'employee_employeeId',
                 'requestManager_employeeId', 'startDate', 'numberOfDays', 'status')
        .where({ ID });

      if (!request) return req.error(404, `Leave request ${ID} not found`);
      if (request.status !== Status.Pending)
        return req.error(400, `Only Pending requests can be approved (current: ${request.status})`);

      await _assertIsManager(req, Employees, request.requestManager_employeeId);
      if (req.errors?.length) return;

      const now = new Date().toISOString();
      const days = _num(request.numberOfDays);

      await UPDATE(LeaveRequests).set({
        status:         Status.Approved,
        approvedBy:     req.user.id,
        approvedAt:     now,
        managerComments: comments,
      }).where({ ID });

      // Move days from pending → used
      const year = new Date(request.startDate).getFullYear();
      await _updatePending(LeaveBalances, request.employee_employeeId,
                           request.leaveType_code, year, days, '-');
      await _updateUsed(LeaveBalances, request.employee_employeeId,
                        request.leaveType_code, year, days, '+');
      await _refreshRemaining(LeaveBalances, request.employee_employeeId,
                              request.leaveType_code, year);

      await _logHistory(ApprovalHistory, {
        request_ID: ID,
        action:     Action.Approved,
        actionBy:   req.user.id,
        actionAt:   now,
        comments,
        fromStatus: Status.Pending,
        toStatus:   Status.Approved,
      });

      return SELECT.one.from(LeaveRequests).where({ ID });
    });

    // ── rejectRequest ────────────────────────────────────────────────────────
    this.on('rejectRequest', LeaveRequests, async (req) => {
      const { ID } = req.params[0];
      const { reason } = req.data;

      const request = await SELECT.one.from(LeaveRequests)
        .columns('*', 'leaveType_code', 'employee_employeeId',
                 'requestManager_employeeId', 'startDate', 'numberOfDays', 'status')
        .where({ ID });

      if (!request) return req.error(404, `Leave request ${ID} not found`);
      if (request.status !== Status.Pending)
        return req.error(400, `Only Pending requests can be rejected (current: ${request.status})`);

      await _assertIsManager(req, Employees, request.requestManager_employeeId);
      if (req.errors?.length) return;

      const now = new Date().toISOString();
      const days = _num(request.numberOfDays);

      await UPDATE(LeaveRequests).set({
        status:          Status.Rejected,
        rejectedBy:      req.user.id,
        rejectedAt:      now,
        rejectionReason: reason,
      }).where({ ID });

      // Release pending days back to balance
      const year = new Date(request.startDate).getFullYear();
      await _updatePending(LeaveBalances, request.employee_employeeId,
                           request.leaveType_code, year, days, '-');
      await _refreshRemaining(LeaveBalances, request.employee_employeeId,
                              request.leaveType_code, year);

      await _logHistory(ApprovalHistory, {
        request_ID: ID,
        action:     Action.Rejected,
        actionBy:   req.user.id,
        actionAt:   now,
        comments:   reason,
        fromStatus: Status.Pending,
        toStatus:   Status.Rejected,
      });

      return SELECT.one.from(LeaveRequests).where({ ID });
    });

    // ── cancel ──────────────────────────────────────────────────────────────
    this.on('cancel', LeaveRequests, async (req) => {
      const { ID } = req.params[0];
      const { reason } = req.data;

      const request = await SELECT.one.from(LeaveRequests)
        .columns('*', 'leaveType_code', 'employee_employeeId',
                 'startDate', 'numberOfDays', 'status')
        .where({ ID });

      if (!request) return req.error(404, `Leave request ${ID} not found`);
      const cancellable = [Status.Draft, Status.Pending];
      if (!cancellable.includes(request.status))
        return req.error(400,
          `Only Draft or Pending requests can be cancelled (current: ${request.status})`);

      const now = new Date().toISOString();
      const days = _num(request.numberOfDays);

      await UPDATE(LeaveRequests).set({
        status:             Status.Cancelled,
        cancelledBy:        req.user.id,
        cancelledAt:        now,
        cancellationReason: reason,
      }).where({ ID });

      // If it was pending, release pending days
      if (request.status === Status.Pending) {
        const year = new Date(request.startDate).getFullYear();
        await _updatePending(LeaveBalances, request.employee_employeeId,
                             request.leaveType_code, year, days, '-');
        await _refreshRemaining(LeaveBalances, request.employee_employeeId,
                                request.leaveType_code, year);
      }

      await _logHistory(ApprovalHistory, {
        request_ID: ID,
        action:     Action.Cancelled,
        actionBy:   req.user.id,
        actionAt:   now,
        comments:   reason,
        fromStatus: request.status,
        toStatus:   Status.Cancelled,
      });

      return SELECT.one.from(LeaveRequests).where({ ID });
    });

    // ── withdraw ─────────────────────────────────────────────────────────────
    this.on('withdraw', LeaveRequests, async (req) => {
      const { ID } = req.params[0];
      const { reason } = req.data;

      const request = await SELECT.one.from(LeaveRequests)
        .columns('*', 'leaveType_code', 'employee_employeeId',
                 'startDate', 'numberOfDays', 'status')
        .where({ ID });

      if (!request) return req.error(404, `Leave request ${ID} not found`);
      if (request.status !== Status.Approved)
        return req.error(400,
          `Only Approved requests can be withdrawn (current: ${request.status})`);

      const now = new Date().toISOString();
      const days = _num(request.numberOfDays);
      const year  = new Date(request.startDate).getFullYear();

      await UPDATE(LeaveRequests).set({
        status:             Status.Withdrawn,
        cancelledBy:        req.user.id,
        cancelledAt:        now,
        cancellationReason: reason,
      }).where({ ID });

      // Restore used days
      await _updateUsed(LeaveBalances, request.employee_employeeId,
                        request.leaveType_code, year, days, '-');
      await _refreshRemaining(LeaveBalances, request.employee_employeeId,
                              request.leaveType_code, year);

      await _logHistory(ApprovalHistory, {
        request_ID: ID,
        action:     Action.Withdrawn,
        actionBy:   req.user.id,
        actionAt:   now,
        comments:   reason,
        fromStatus: Status.Approved,
        toStatus:   Status.Withdrawn,
      });

      return SELECT.one.from(LeaveRequests).where({ ID });
    });

    // ── checkLeaveBalance ────────────────────────────────────────────────────
    this.on('checkLeaveBalance', async (req) => {
      const { employeeId, leaveTypeCode, startDate, endDate } = req.data;

      const year = new Date(startDate).getFullYear();
      const requested = _calcWorkingDays(startDate, endDate, false, false);

      const balance = await _getBalance(
        LeaveBalances, employeeId, leaveTypeCode, year
      );
      const available = _num(balance?.remaining);

      return {
        available,
        requested,
        sufficient: available >= requested,
        message: available >= requested
          ? `${available} days available, ${requested} requested`
          : `Insufficient: only ${available} of ${requested} days available`,
      };
    });

    // ── getLeaveCalendar ─────────────────────────────────────────────────────
    this.on('getLeaveCalendar', async (req) => {
      const { startDate, endDate } = req.data;

      return SELECT.from(LeaveRequests)
        .columns(
          'employee.fullName as employeeName',
          'leaveType.name    as leaveType',
          'startDate', 'endDate', 'status', 'numberOfDays'
        )
        .where(`startDate <= '${endDate}' AND endDate >= '${startDate}'`)
        .and(`status IN ('${Status.Pending}', '${Status.Approved}')`);
    });

    // ── Auto-populate employee from the logged-in user ───────────────────────
    // ── Auto-populate employee + requestManager from the logged-in user ─────────
    // Runs in a single handler so employee is resolved before manager lookup.
    const _autoEmployee = async (req) => {
      if (!req.data.employee_employeeId) {
        const emp = await SELECT.one.from(Employees)
          .columns('employeeId', 'managerId')
          .where({ userId: req.user.id });
        if (emp) {
          req.data.employee_employeeId = emp.employeeId;
          if (!req.data.requestManager_employeeId && emp.managerId) {
            const mgr = await SELECT.one.from(Employees)
              .columns('employeeId')
              .where({ userId: emp.managerId });
            if (mgr) req.data.requestManager_employeeId = mgr.employeeId;
          }
        }
      } else if (!req.data.requestManager_employeeId) {
        // Employee already set (e.g. manager changed request on behalf) — still auto-fill manager
        const emp = await SELECT.one.from(Employees)
          .columns('managerId')
          .where({ employeeId: req.data.employee_employeeId });
        if (emp?.managerId) {
          const mgr = await SELECT.one.from(Employees)
            .columns('employeeId')
            .where({ userId: emp.managerId });
          if (mgr) req.data.requestManager_employeeId = mgr.employeeId;
        }
      }
    };
    for (const t of _allTargets) this.before('CREATE', t, _autoEmployee);

    // ── Auto-calculate numberOfDays before CREATE/UPDATE ─────────────────────
    // Recalculates whenever startDate or endDate is touched. When only one date
    // arrives in a PATCH, fetches the other from the existing draft row.
    // Lookup uses LeaveRequestDrafts (not the active entity) so draft-only
    // records (not yet activated) are found correctly.
    const _calcDays = async (req) => {
      let { startDate, endDate, halfDayStart, halfDayEnd } = req.data;
      if (!startDate && !endDate) return;
      if (!startDate || !endDate) {
        const { ID } = req.params?.[0] ?? {};
        if (ID) {
          const lookupFrom = LeaveRequestDrafts ?? LeaveRequests;
          const cur = await SELECT.one.from(lookupFrom)
            .columns('startDate', 'endDate', 'halfDayStart', 'halfDayEnd')
            .where({ ID });
          if (cur) {
            startDate    = startDate    ?? cur.startDate;
            endDate      = endDate      ?? cur.endDate;
            halfDayStart = halfDayStart ?? cur.halfDayStart;
            halfDayEnd   = halfDayEnd   ?? cur.halfDayEnd;
          }
        }
      }
      if (startDate && endDate) {
        req.data.numberOfDays = _calcWorkingDays(
          startDate, endDate, halfDayStart ?? false, halfDayEnd ?? false
        );
      }
    };
    for (const t of _allTargets) this.before(['CREATE', 'UPDATE'], t, _calcDays);

    // ── Validate dates on CREATE/UPDATE ──────────────────────────────────────
    const _validateDatesHandler = (req) => {
      const { startDate, endDate } = req.data;
      if (startDate && endDate) _validateDates(req, startDate, endDate);
    };
    for (const t of _allTargets) this.before(['CREATE', 'UPDATE'], t, _validateDatesHandler);

    await super.init();
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// HRAdminService handlers
// ─────────────────────────────────────────────────────────────────────────────
module.exports.HRAdminService = class HRAdminService extends cds.ApplicationService {
  async init() {
    const { LeaveBalances, Employees, LeaveTypes } = this.entities;

    // ── allocateAnnualLeave ──────────────────────────────────────────────────
    this.on('allocateAnnualLeave', async (req) => {
      const { fiscalYear, leaveTypeCode } = req.data;

      const leaveType = await SELECT.one.from(LeaveTypes)
        .where({ code: leaveTypeCode });
      if (!leaveType)
        return req.error(404, `Leave type '${leaveTypeCode}' not found`);

      const employees = await SELECT.from(Employees).where({ isActive: true });
      let processed = 0;

      for (const emp of employees) {
        const existing = await SELECT.one.from(LeaveBalances).where({
          employee_employeeId: emp.employeeId,
          leaveType_code: leaveTypeCode,
          fiscalYear,
        });

        if (!existing) {
          await INSERT.into(LeaveBalances).entries({
            ID: cds.utils.uuid(),
            employee_employeeId: emp.employeeId,
            leaveType_code: leaveTypeCode,
            fiscalYear,
            allocated:  leaveType.maxDaysPerYear ?? 0,
            carryForward: 0,
            used:       0,
            pending:    0,
            remaining:  leaveType.maxDaysPerYear ?? 0,
          });
          processed++;
        }
      }

      return { processed, message: `Allocated leave for ${processed} employees` };
    });

    // ── processCarryForward ──────────────────────────────────────────────────
    this.on('processCarryForward', async (req) => {
      const { fromYear, leaveTypeCode } = req.data;
      const toYear = fromYear + 1;

      const leaveType = await SELECT.one.from(LeaveTypes)
        .where({ code: leaveTypeCode });
      if (!leaveType)
        return req.error(404, `Leave type '${leaveTypeCode}' not found`);

      const fromBalances = await SELECT.from(LeaveBalances).where({
        leaveType_code: leaveTypeCode,
        fiscalYear: fromYear,
      });

      let processed = 0;
      const maxCarry = leaveType.carryForwardDays ?? 0;

      for (const bal of fromBalances) {
        const carryAmount = Math.min(_num(bal.remaining), maxCarry);
        if (carryAmount <= 0) continue;

        const toBalance = await SELECT.one.from(LeaveBalances).where({
          employee_employeeId: bal.employee_employeeId,
          leaveType_code: leaveTypeCode,
          fiscalYear: toYear,
        });

        if (toBalance) {
          await UPDATE(LeaveBalances)
            .set({ carryForward: _num(toBalance.carryForward) + carryAmount })
            .where({ ID: toBalance.ID });
          await _refreshRemaining(
            LeaveBalances, bal.employee_employeeId, leaveTypeCode, toYear
          );
        } else {
          const allocated = leaveType.maxDaysPerYear ?? 0;
          await INSERT.into(LeaveBalances).entries({
            ID: cds.utils.uuid(),
            employee_employeeId: bal.employee_employeeId,
            leaveType_code: leaveTypeCode,
            fiscalYear: toYear,
            allocated,
            carryForward: carryAmount,
            used:      0,
            pending:   0,
            remaining: allocated + carryAmount,
          });
        }
        processed++;
      }

      return {
        processed,
        message: `Carry-forward processed for ${processed} employees`,
      };
    });

    await super.init();
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

// HANA's hdb driver returns Decimal columns as strings (e.g. "5.00"), not numbers.
// Plain JS arithmetic on strings produces string concatenation instead of addition.
// Always convert through _num() before arithmetic to avoid "Wrong input for DECIMAL type".
const _num = v => parseFloat(v) || 0;

function _validateDates(req, startDate, endDate) {
  const start = new Date(startDate);
  const end   = new Date(endDate);
  if (start > end)
    req.error(400, 'Start date must be on or before end date');
}

// Simple Mon–Fri working day counter (no public holiday awareness).
// For production, integrate a holiday calendar.
function _calcWorkingDays(startDate, endDate, halfDayStart = false, halfDayEnd = false) {
  const start = new Date(startDate);
  const end   = new Date(endDate);
  let days = 0;
  const cursor = new Date(start);
  while (cursor <= end) {
    const dow = cursor.getDay();
    if (dow !== 0 && dow !== 6) days++;
    cursor.setDate(cursor.getDate() + 1);
  }
  if (halfDayStart && days > 0) days -= 0.5;
  if (halfDayEnd   && days > 0) days -= 0.5;
  return Math.max(days, 0);
}

async function _getBalance(LeaveBalances, employeeId, leaveTypeCode, year) {
  return SELECT.one.from(LeaveBalances).where({
    employee_employeeId: employeeId,
    leaveType_code:      leaveTypeCode,
    fiscalYear:          year,
  });
}

async function _updatePending(LeaveBalances, employeeId, leaveTypeCode, year, days, op) {
  const bal = await _getBalance(LeaveBalances, employeeId, leaveTypeCode, year);
  if (!bal) return;
  const newPending = op === '+'
    ? _num(bal.pending) + days
    : Math.max(_num(bal.pending) - days, 0);
  await UPDATE(LeaveBalances)
    .set({ pending: newPending, remaining: _num(bal.allocated) + _num(bal.carryForward) - _num(bal.used) - newPending })
    .where({ ID: bal.ID });
}

async function _updateUsed(LeaveBalances, employeeId, leaveTypeCode, year, days, op) {
  const bal = await _getBalance(LeaveBalances, employeeId, leaveTypeCode, year);
  if (!bal) return;
  const newUsed = op === '+'
    ? _num(bal.used) + days
    : Math.max(_num(bal.used) - days, 0);
  await UPDATE(LeaveBalances)
    .set({ used: newUsed })
    .where({ ID: bal.ID });
}

async function _refreshRemaining(LeaveBalances, employeeId, leaveTypeCode, year) {
  const bal = await _getBalance(LeaveBalances, employeeId, leaveTypeCode, year);
  if (!bal) return;
  const remaining = _num(bal.allocated) + _num(bal.carryForward)
                  - _num(bal.used) - _num(bal.pending);
  await UPDATE(LeaveBalances)
    .set({ remaining: Math.max(remaining, 0) })
    .where({ ID: bal.ID });
}

async function _logHistory(ApprovalHistory, entry) {
  await INSERT.into(ApprovalHistory).entries({
    ID: cds.utils.uuid(),
    ...entry,
  });
}

async function _assertIsManager(req, Employees, requestManagerEmployeeId) {
  if (!requestManagerEmployeeId) {
    req.error(403, 'No approving manager designated for this request');
    return;
  }
  const manager = await SELECT.one.from(Employees)
    .columns('userId')
    .where({ employeeId: requestManagerEmployeeId });
  if (!manager || manager.userId !== req.user.id) {
    req.error(403, 'Only the designated approving manager can approve or reject this request');
  }
}
