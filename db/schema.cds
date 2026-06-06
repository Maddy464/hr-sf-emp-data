namespace sap.hr;

using { managed, cuid } from '@sap/cds/common';

// ── Unit Types & Status Enums ─────────────────────────────────────────────────

type UnitType : String(10) enum {
  Days  = 'DAYS';
  Hours = 'HOURS';
}

type LeaveStatus : String(20) enum {
  Draft     = 'DRAFT';
  Pending   = 'PENDING';
  Approved  = 'APPROVED';
  Rejected  = 'REJECTED';
  Cancelled = 'CANCELLED';
  Withdrawn = 'WITHDRAWN';
}

type ApprovalAction : String(20) enum {
  Submitted = 'SUBMITTED';
  Approved  = 'APPROVED';
  Rejected  = 'REJECTED';
  Cancelled = 'CANCELLED';
  Withdrawn = 'WITHDRAWN';
  Modified  = 'MODIFIED';
}

// ── Leave Types (SF: TimeType) ────────────────────────────────────────────────

/**
 * Catalogue of leave types (Annual, Sick, Maternity, Paternity, Unpaid, etc.)
 * Mirrors SAP SuccessFactors TimeType configuration.
 */
entity LeaveTypes : managed {
  key code                 : String(20);
      name                 : String(100) @mandatory;
      description          : String(500);
      unitType             : UnitType    default #Days;
      isPaid               : Boolean     default true;
      maxDaysPerYear       : Decimal(5,2);
      maxConsecutiveDays   : Decimal(5,2);
      minNoticeDays        : Integer     default 0;
      requiresApproval     : Boolean     default true;
      requiresAttachment   : Boolean     default false;
      carryForwardDays     : Decimal(5,2) default 0;
      allowNegativeBalance : Boolean     default false;
      isActive             : Boolean     default true;
      leaveBalances        : Association to many LeaveBalances
                               on leaveBalances.leaveType = $self;
}

// ── Employees (SF: PerPerson + EmpEmployment) ─────────────────────────────────

/**
 * Employee master — sourced from SF Employee Central or maintained locally.
 * managerId enables the self-referential reporting hierarchy used for
 * manager-level approval queries.
 */
entity Employees : managed {
  key employeeId    : String(20);
      firstName     : String(100) @mandatory;
      lastName      : String(100) @mandatory;
      fullName      : String(200);
      email         : String(255) @mandatory;
      userId        : String(100);           // SF userId / IDP subject
      jobTitle      : String(100);
      department    : String(100);
      costCenter    : String(20);
      managerId     : String(100);   // stores manager's userId — enables $user auth checks
      manager       : Association to Employees
                        on manager.userId = managerId;
      directReports : Association to many Employees
                        on directReports.managerId = $self.userId;
      hireDate      : Date;
      terminationDate : Date;
      isActive      : Boolean default true;
      leaveBalances : Composition of many LeaveBalances
                        on leaveBalances.employee = $self;
      leaveRequests : Composition of many LeaveRequests
                        on leaveRequests.employee = $self;
}

// ── Leave Balances (SF: TimeAccountDetail) ────────────────────────────────────

/**
 * Tracks leave quota per employee, per leave type, per fiscal year.
 * `remaining` is kept in sync by service handlers on each status transition.
 */
entity LeaveBalances : managed {
  key ID            : UUID;
      employee      : Association to Employees  @mandatory;
      leaveType     : Association to LeaveTypes @mandatory;
      fiscalYear    : Integer                   @mandatory;
      allocated     : Decimal(7,2) default 0;   // days granted
      carryForward  : Decimal(7,2) default 0;   // brought forward from prior year
      used          : Decimal(7,2) default 0;   // approved & taken
      pending       : Decimal(7,2) default 0;   // awaiting approval
      remaining     : Decimal(7,2) default 0;   // allocated + carryForward - used - pending
}

// ── Leave Requests (SF: EmployeeTimeOff) ──────────────────────────────────────

/**
 * Core leave request entity.
 * Draft-enabled for Fiori — employees can save a draft before submitting.
 * Status transitions are enforced by bound action handlers.
 */
entity LeaveRequests : managed, cuid {
      employee        : Association to Employees  @mandatory;
      requestManager  : Association to Employees;   // designated approver (defaults to employee's manager)
      leaveType       : Association to LeaveTypes @mandatory;
      startDate     : Date @mandatory;
      endDate       : Date @mandatory;
      numberOfDays  : Decimal(5,2);
      halfDayStart  : Boolean default false;    // first day is half day
      halfDayEnd    : Boolean default false;    // last day is half day
      requestNotes  : String(2000);
      status        : LeaveStatus default #Draft;
      // ── Submission ──────────────────────────────────────────────────────────
      submittedAt   : Timestamp;
      // ── Approval ────────────────────────────────────────────────────────────
      approvedBy    : String(255);
      approvedAt    : Timestamp;
      managerComments : String(2000);
      // ── Rejection ───────────────────────────────────────────────────────────
      rejectedBy    : String(255);
      rejectedAt    : Timestamp;
      rejectionReason : String(2000);
      // ── Cancellation / Withdrawal ────────────────────────────────────────────
      cancelledBy   : String(255);
      cancelledAt   : Timestamp;
      cancellationReason : String(2000);
      // ── Child compositions ──────────────────────────────────────────────────
      attachments       : Composition of many LeaveAttachments
                            on attachments.request = $self;
      approvalHistory   : Composition of many ApprovalHistory
                            on approvalHistory.request = $self;
}

// ── Leave Attachments (SF: EmployeeTimeAttachment) ───────────────────────────

/**
 * Supporting documents — medical certificates, etc.
 * Content stored as BLOB; mimeType exposed as OData media type.
 */
entity LeaveAttachments : cuid {
      request       : Association to LeaveRequests @mandatory;
      fileName      : String(255) @mandatory;
      mimeType      : String(100);
      content       : LargeBinary @odata.mediaContentType: 'mimeType';
      uploadedAt    : Timestamp   @cds.on.insert: $now;
      uploadedBy    : String(255) @cds.on.insert: $user;
}

// ── Approval History (SF: WorkflowRequest audit) ──────────────────────────────

/**
 * Immutable audit trail — one record per status transition.
 * Never updated after insert; records who did what and when.
 */
entity ApprovalHistory : cuid {
      request       : Association to LeaveRequests @mandatory;
      action        : ApprovalAction @mandatory;
      actionBy      : String(255) @cds.on.insert: $user;
      actionAt      : Timestamp   @cds.on.insert: $now;
      comments      : String(2000);
      fromStatus    : LeaveStatus;
      toStatus      : LeaveStatus;
}
