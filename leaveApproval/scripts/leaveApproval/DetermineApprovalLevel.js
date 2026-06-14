var days = $.context.numberOfDays;
var type = $.context.leaveTypeCode || $.context.leaveType;
var bal  = $.context.balanceRemaining;

if (days <= 1) {
    $.context.approvalLevel = 'AUTO_APPROVE';
} else if (days > 5) {
    $.context.approvalLevel = 'HR_APPROVAL';
} else if (type === 'UNPAID') {
    $.context.approvalLevel = 'MANAGER_APPROVAL';
} else if (bal < 0) {
    $.context.approvalLevel = 'MANAGER_APPROVAL';
} else {
    $.context.approvalLevel = 'MANAGER_APPROVAL';
}
