// PrepareRejectPayload.js
// Runs in the SAP Workflow script task engine ($.context / $.info API).
// Builds the JSON body that the Reject ServiceTask will POST to
// WorkflowCallbackService.rejectLeave.
//
// Expected context inputs (set when the workflow instance is triggered):
//   $.context.leaveRequestId  — UUID of the leave request
//   $.context.managerUserId   — userId of the approving manager
//
// Expected context inputs (set by the ApproveLeaveform.form decision notes field):
//   $.context.decisionNotes   — mandatory rejection reason entered by the manager

$.context.rejectPayload = {
    leaveRequestId:     $.context.leaveRequestId,
    workflowInstanceId: $.info.id,
    actionBy:           $.context.managerUserId,
    reason:             $.context.decisionNotes || "Rejected by manager"
};
