// WorkflowCallbackService — REST callback endpoint for SAP Build Process Automation.
//
// Flow:
//   1. Employee submits leave request → LeaveService.submit triggers an SBPA
//      workflow instance (stores the instance ID on the request).
//   2. SBPA creates a user task in the manager's SAP My Inbox (Task Center).
//   3. Manager acts from My Inbox → SBPA resumes the process and calls one of
//      these actions using XSUAA client credentials (WorkflowCallback scope).
//   4. This service updates the leave request status and adjusts balances,
//      identical to what ManagerService does when acting via mgr_ui.
//
// Auth: XSUAA client credentials grant — SBPA is assigned the WorkflowCallback
// role collection, which holds the WorkflowCallback scope from xs-security.json.
// In development, use the mock user sbpa-callback / callback for testing.
//
// Mount path: /odata/v4/workflow
// Approve: POST /odata/v4/workflow/approveLeave
// Reject:  POST /odata/v4/workflow/rejectLeave

service WorkflowCallbackService @(path: '/odata/v4/workflow', requires: 'authenticated-user') {

  // Called by SBPA when manager clicks Approve in My Inbox
  action approveLeave(
    leaveRequestId     : UUID           not null,
    workflowInstanceId : String(100),
    actionBy           : String(255)    not null,
    comments           : String(2000)
  ) returns {
    status  : String;
    message : String;
  };

  // Called by SBPA when manager clicks Reject in My Inbox
  action rejectLeave(
    leaveRequestId     : UUID           not null,
    workflowInstanceId : String(100),
    actionBy           : String(255)    not null,
    reason             : String(2000)   not null
  ) returns {
    status  : String;
    message : String;
  };
}
