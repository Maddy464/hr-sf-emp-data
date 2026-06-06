using { sap.hr as hr } from '../db/schema';

// ─────────────────────────────────────────────────────────────────────────────
// LeaveService  — primary service for employees and managers
// ─────────────────────────────────────────────────────────────────────────────
service LeaveService @(requires: 'authenticated-user') {

  // ── Employee Directory (read-only) ─────────────────────────────────────────
  // Used for "delegate to" lookups and manager display names.
  @readonly
  entity Employees as projection on hr.Employees {
    employeeId, firstName, lastName, fullName,
    email, userId, jobTitle, department,
    managerId, manager, isActive
  }

  // ── Leave Type Catalogue (code list) ──────────────────────────────────────
  @readonly
  entity LeaveTypes as projection on hr.LeaveTypes
    where isActive = true;

  // ── My Leave Balances ──────────────────────────────────────────────────────
  // Restricted by auth annotation in leave-service-auth.cds to own records.
  entity MyLeaveBalances as projection on hr.LeaveBalances {
    *,
    employee.fullName  as employeeName  : String,
    leaveType.name     as leaveTypeName : String,
    leaveType.unitType as unitType      : String
  }

  // ── Leave Requests ─────────────────────────────────────────────────────────
  // @odata.draft.enabled allows employees to save drafts in Fiori before submit.
  // Bound actions enforce the status-transition lifecycle.
  @odata.draft.enabled
  @cds.redirection.target
  entity LeaveRequests as projection on hr.LeaveRequests {
    *,
    employee.fullName           as employeeName          : String,
    employee.department         as department            : String,
    employee.managerId          as managerId             : String,
    requestManager.fullName     as requestManagerName    : String,
    leaveType.name         as leaveTypeName     : String,
    leaveType.unitType     as unitType          : String,
    leaveType.isPaid       as isPaid            : Boolean,
    leaveType.requiresAttachment as requiresAttachment : Boolean,
    // Criticality for Fiori status colour: 3=Positive 2=Critical 1=Negative 0=Neutral
    // Computed in after-READ handler — keeps HANA from parameterising integer
    // literals in a CASE expression (hdb driver rejects non-string params).
    virtual criticality : Integer,
    // Per-action availability flags — encode role + status in one boolean each.
    // Core.OperationAvailable on a simple path: false → HIDDEN on Object Page,
    // DISABLED on List Report toolbar (FE V4 spec).
    virtual submitEnabled   : Boolean,
    virtual approveEnabled  : Boolean,
    virtual rejectEnabled   : Boolean,
    virtual cancelEnabled   : Boolean,
    virtual withdrawEnabled : Boolean
  } actions {
    // Employee actions
    action submit   (notes   : String(2000))           returns LeaveRequests;
    action cancel   (reason  : String(2000))           returns LeaveRequests;
    action withdraw (reason  : String(2000) not null)  returns LeaveRequests;
    // Manager actions
    action approve  (comments : String(2000))          returns LeaveRequests;
    action rejectRequest (reason : String(2000) not null) returns LeaveRequests;
  }

  // ── Team Leave Requests (manager view) ────────────────────────────────────
  // Read-only projection filtered to direct reports in auth annotations.
  @readonly
  entity TeamLeaveRequests as projection on hr.LeaveRequests {
    *,
    employee.fullName   as employeeName   : String,
    employee.department as department     : String,
    leaveType.name      as leaveTypeName  : String
  }

  // ── Approval History (read-only audit trail) ───────────────────────────────
  @readonly
  entity ApprovalHistory as projection on hr.ApprovalHistory;

  // ── Functions ──────────────────────────────────────────────────────────────

  // Check if employee has sufficient balance before submitting.
  function checkLeaveBalance(
    employeeId    : String,
    leaveTypeCode : String,
    startDate     : Date,
    endDate       : Date
  ) returns {
    available  : Decimal;
    requested  : Decimal;
    sufficient : Boolean;
    message    : String;
  };

  // Returns pending/approved requests that overlap a given date range.
  function getLeaveCalendar(
    startDate : Date,
    endDate   : Date
  ) returns array of {
    employeeName : String;
    leaveType    : String;
    startDate    : Date;
    endDate      : Date;
    status       : String;
    numberOfDays : Decimal;
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// HRAdminService  — full access for HR administrators
// ─────────────────────────────────────────────────────────────────────────────
service HRAdminService @(requires: 'HRAdmin') {

  entity Employees       as projection on hr.Employees;
  entity LeaveTypes      as projection on hr.LeaveTypes;
  entity LeaveBalances   as projection on hr.LeaveBalances;
  entity LeaveRequests   as projection on hr.LeaveRequests;
  entity ApprovalHistory as projection on hr.ApprovalHistory;

  // Bulk allocate leave balance for a fiscal year
  action allocateAnnualLeave(
    fiscalYear    : Integer not null,
    leaveTypeCode : String  not null
  ) returns {
    processed : Integer;
    message   : String;
  };

  // Carry forward unused balance to next fiscal year
  action processCarryForward(
    fromYear      : Integer not null,
    leaveTypeCode : String  not null
  ) returns {
    processed : Integer;
    message   : String;
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Status-transition flow annotation (CAP Gamma feature — @sap/cds ^9)
// Declares which actions are valid from which states, enabling runtime
// enforcement and automatic Fiori UI button visibility.
// ─────────────────────────────────────────────────────────────────────────────
annotate LeaveService.LeaveRequests with @flow.status: status actions {
  submit   @from: [ #Draft ]                  @to: #Pending;
  approve  @from: [ #Pending ]                @to: #Approved;
  rejectRequest @from: [ #Pending ]           @to: #Rejected;
  cancel   @from: [ #Draft, #Pending ]        @to: #Cancelled;
  withdraw @from: [ #Approved ]               @to: #Withdrawn;
}
