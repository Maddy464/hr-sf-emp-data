// Authorization annotations — kept separate from service definitions
// following CAP best-practice separation of concerns.
// See: https://cap.cloud.sap/docs/guides/security/authorization#separation-of-concerns

using { LeaveService, HRAdminService } from './leave-service';

// ─────────────────────────────────────────────────────────────────────────────
// LeaveService
// ─────────────────────────────────────────────────────────────────────────────

// Employees directory: any authenticated user can read
annotate LeaveService.Employees with @(restrict: [
  { grant: 'READ', to: ['Employee', 'Manager', 'HRAdmin'] }
]);

// Leave type catalogue: any authenticated user can read
annotate LeaveService.LeaveTypes with @(restrict: [
  { grant: 'READ', to: ['Employee', 'Manager', 'HRAdmin'] }
]);

// My Leave Balances: employees see only their own balance records
annotate LeaveService.MyLeaveBalances with @(restrict: [
  { grant: 'READ', to: 'Employee',
    where: 'employee.userId = $user' },
  { grant: 'READ', to: ['Manager', 'HRAdmin'] }
]);

// Leave Requests:
//   - Employees: full CRUD on own drafts; submit/cancel/withdraw own requests
//   - Managers : read team requests; approve/reject
//   - HRAdmin  : full access
annotate LeaveService.LeaveRequests with @(restrict: [
  { grant: ['READ', 'WRITE'],
    to: 'Employee',
    where: 'createdBy = $user' },
  { grant: ['submit', 'cancel', 'withdraw'],
    to: 'Employee',
    where: 'createdBy = $user' },
  { grant: ['READ', 'approve', 'rejectRequest'],
    to: 'Manager',
    where: 'requestManager.userId = $user' },
  { grant: '*',
    to: 'HRAdmin' }
]);

// Team Leave Requests: managers see only their direct reports' requests
annotate LeaveService.TeamLeaveRequests with @(restrict: [
  { grant: 'READ', to: 'Manager',
    where: 'employee.managerId = $user' },
  { grant: 'READ', to: 'HRAdmin' }
]);

// Approval History: employees see history of their own requests; managers/HRAdmin see all
annotate LeaveService.ApprovalHistory with @(restrict: [
  { grant: 'READ', to: 'Employee',
    where: 'request.createdBy = $user' },
  { grant: 'READ', to: ['Manager', 'HRAdmin'] }
]);

// ─────────────────────────────────────────────────────────────────────────────
// HRAdminService — already @requires: 'HRAdmin' at service level;
// entity-level annotations provide explicit grant declarations for audit clarity.
// ─────────────────────────────────────────────────────────────────────────────

annotate HRAdminService.Employees with @(restrict: [
  { grant: '*', to: 'HRAdmin' }
]);

annotate HRAdminService.LeaveTypes with @(restrict: [
  { grant: '*', to: 'HRAdmin' }
]);

annotate HRAdminService.LeaveBalances with @(restrict: [
  { grant: '*', to: 'HRAdmin' }
]);

annotate HRAdminService.LeaveRequests with @(restrict: [
  { grant: '*', to: 'HRAdmin' }
]);

annotate HRAdminService.ApprovalHistory with @(restrict: [
  { grant: 'READ', to: 'HRAdmin' }
]);
