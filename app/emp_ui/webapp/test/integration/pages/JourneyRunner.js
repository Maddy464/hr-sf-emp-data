sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"com/sap/sf/empui/test/integration/pages/LeaveRequestsList",
	"com/sap/sf/empui/test/integration/pages/LeaveRequestsObjectPage",
	"com/sap/sf/empui/test/integration/pages/ApprovalHistoryObjectPage"
], function (JourneyRunner, LeaveRequestsList, LeaveRequestsObjectPage, ApprovalHistoryObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('com/sap/sf/empui') + '/test/flp.html#app-preview',
        pages: {
			onTheLeaveRequestsList: LeaveRequestsList,
			onTheLeaveRequestsObjectPage: LeaveRequestsObjectPage,
			onTheApprovalHistoryObjectPage: ApprovalHistoryObjectPage
        },
        async: true
    });

    return runner;
});

