using { sap.hr as hr } from '../db/schema';

// ─────────────────────────────────────────────────────────────────────────────
// ManagerService — dedicated approval-workflow service for Managers.
//
// CAP best-practice: one service per role, minimal projection, auth in a
// separate file.  Mount path: /odata/v4/manager
//
// What a Manager does here:
//   - Browse pending / historical leave requests routed to them
//   - Approve, reject, or cancel individual requests
//   - Check team leave balances
//
// What is NOT in this service (belongs in LeaveService / HRAdminService):
//   - Creating / submitting leave requests  (Employee role)
//   - Withdrawing approved requests         (Employee role)
//   - Bulk balance allocation               (HRAdmin role)
// ─────────────────────────────────────────────────────────────────────────────
service ManagerService @(requires: 'Manager') {

  // ── Team Leave Requests ───────────────────────────────────────────────────
  // Filtered by auth to requests where requestManager.userId = $user.
  // Read-only OData CRUD; state mutations happen via bound actions only.
  entity TeamRequests as projection on hr.LeaveRequests {
    
    *,
    employee.fullName        as employeeName       : String,
    employee.department      as department         : String,
    employee.jobTitle        as employeeJobTitle   : String,
    employee.email           as employeeEmail      : String,
    requestManager.fullName  as requestManagerName : String,
    leaveType.name           as leaveTypeName      : String,
    leaveType.unitType       as unitType           : String,
    leaveType.isPaid         as isPaid             : Boolean,
    // Criticality drives status colour in Fiori: 3=Positive 2=Critical 1=Negative
    // Computed in after-READ handler — avoids hdb "Argument must be a string" bug.
    virtual criticality : Integer,
    // Per-action availability flags — used by Core.OperationAvailable in Fiori
    virtual approveEnabled   : Boolean,
    virtual rejectEnabled    : Boolean,
    virtual cancelEnabled    : Boolean,
  } actions {
    action approve       (comments : String(2000))          returns TeamRequests;
    action rejectRequest (reason   : String(2000) not null) returns TeamRequests;
    action cancel        (reason   : String(2000))          returns TeamRequests;
  }

  // ── Team Leave Balances ───────────────────────────────────────────────────
  // Auth filter: employee.managerId = $user (org-chart based).
  // Lets the manager see remaining / used days for their direct reports.
  @readonly
  entity TeamLeaveBalances as projection on hr.LeaveBalances {
    *,
    employee.fullName    as employeeName  : String,
    employee.department  as department    : String,
    leaveType.name       as leaveTypeName : String,
    leaveType.unitType   as unitType      : String,
  }

  // ── Employee Directory (read-only) ────────────────────────────────────────
  // Used for name lookups and team overview in Fiori.
  @readonly
  entity Employees as projection on hr.Employees {
    employeeId, firstName, lastName, fullName,
    email, userId, jobTitle, department, managerId, isActive
  }

  // ── Leave Type Catalogue (read-only) ──────────────────────────────────────
  @readonly
  entity LeaveTypes as projection on hr.LeaveTypes
    where isActive = true;

  // ── Approval History (read-only) ──────────────────────────────────────────
  @readonly
  entity ApprovalHistory as projection on hr.ApprovalHistory;
}
