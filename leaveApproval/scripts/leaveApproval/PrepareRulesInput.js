$.context.rulesInput = {
    RuleServiceId: "96b6314a5fae42f9af9828fd4e5296b0",
    RuleServiceRevision: "000000000000000001",
    Vocabulary: [{
        LeaveRequest: {
            numberOfDays:     $.context.numberOfDays,
            leaveType:        $.context.leaveTypeCode || $.context.leaveType,
            balanceRemaining: $.context.balanceRemaining,
            isPaid:           $.context.isPaid
        }
    }]
};
