// Authorization annotations for ManagerService.
// Kept in a separate file following CAP separation-of-concerns best practice.
// The service itself is already @requires: 'Manager'; these entity-level rules
// further scope each entity to the manager's own data.

using { ManagerService } from './manager-service';

// Team requests: manager sees and acts only on requests where they are the
// designated approver (requestManager.userId = $user).
annotate ManagerService.TeamRequests with @(restrict: [
  { grant: ['READ', 'approve', 'rejectRequest', 'cancel'],
    to: 'Manager',
    where: 'requestManager.userId = $user' },
]);

// Team balances: scoped to the manager's direct reports by org-chart.
// (employee.managerId stores the default manager's userId.)
annotate ManagerService.TeamLeaveBalances with @(restrict: [
  { grant: 'READ', to: 'Manager',
    where: 'employee.managerId = $user' },
]);

// Reference data: any authenticated Manager can read.
annotate ManagerService.Employees     with @(restrict: [{ grant: 'READ', to: 'Manager' }]);
annotate ManagerService.LeaveTypes    with @(restrict: [{ grant: 'READ', to: 'Manager' }]);
annotate ManagerService.ApprovalHistory with @(restrict: [{ grant: 'READ', to: 'Manager' }]);
