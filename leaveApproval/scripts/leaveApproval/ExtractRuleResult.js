var response = $.context.rulesResponse;
if (response && response.Result && response.Result.length > 0) {
    $.context.approvalLevel = response.Result[0].ApprovalDecision.approvalLevel;
    $.context.approvalReason = response.Result[0].ApprovalDecision.reason;
} else {
    $.context.approvalLevel = 'MANAGER_APPROVAL';
    $.context.approvalReason = 'Default - manager approval required';
}
