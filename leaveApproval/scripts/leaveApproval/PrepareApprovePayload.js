// PrepareApprovePayload.js
// Runs in the SAP Workflow script task engine ($.context / $.info API).
// Builds the JSON body that the Approve ServiceTask will POST to
// WorkflowCallbackService.approveLeave.
//
// Expected context inputs (set when the workflow instance is triggered):
//   $.context.leaveRequestId  — UUID of the leave request
//   $.context.managerUserId   — userId of the approving manager
//
// Expected context inputs (set by the ApproveLeaveform.form decision notes field):
//   $.context.decisionNotes   — optional comments entered by the manager

$.context.approvePayload = {
    leaveRequestId:     $.context.leaveRequestId,
    workflowInstanceId: $.info.id,
    actionBy:           $.context.managerUserId,
    comments:           $.context.decisionNotes || ""
};
