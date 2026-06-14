{
	"contents": {
		"56a9836e-6f67-4695-8f3e-8c39bf749efb": {
			"classDefinition": "com.sap.bpm.wfs.Model",
			"id": "com.demo.wf.leaveapproval",
			"subject": "leaveApproval",
			"name": "leaveApproval",
			"documentation": "Leave Approval",
			"lastIds": "62d7f4ed-4063-4c44-af8b-39050bd44926",
			"events": {
				"11a9b5ee-17c0-4159-9bbf-454dcfdcd5c3": {
					"name": "StartEvent1"
				},
				"2798f4e7-bc42-4fad-a248-159095a2f40a": {
					"name": "EndEvent1"
				}
			},
			"activities": {
				"cc111001-0000-0000-0000-000000000001": {
					"name": "Determine Approval Level"
				},
				"cc111004-0000-0000-0000-000000000001": {
					"name": "Approval Level Check"
				},
				"7b6d4489-4c98-4f87-a72b-accb92aa36fc": {
					"name": "Approve Leave"
				},
				"ff8cf4e2-d9e6-42a5-a004-2f00384f97f2": {
					"name": "RequestDecison"
				},
				"aa111001-0000-0000-0000-000000000001": {
					"name": "Prepare Approve Payload"
				},
				"aa111002-0000-0000-0000-000000000001": {
					"name": "Prepare Reject Payload"
				},
				"07a00e15-6672-4d38-8080-491fe53c8433": {
					"name": "Approve"
				},
				"2b1598f9-cb9e-41f4-831c-2c41599118db": {
					"name": "Reject"
				}
			},
			"sequenceFlows": {
				"c6b99f32-5fe6-4ab6-b60a-80fba1b9ae0f": {
					"name": "SequenceFlow1"
				},
				"dd111002-0000-0000-0000-000000000001": {
					"name": "SequenceFlow15"
				},
				"dd111005-0000-0000-0000-000000000001": {
					"name": "AutoApprove"
				},
				"dd111006-0000-0000-0000-000000000001": {
					"name": "ManagerApproval"
				},
				"d268dca6-defb-4e67-9c4e-2b5067271fca": {
					"name": "SequenceFlow2"
				},
				"941d5e92-04a7-4264-84b6-4668c01d1cca": {
					"name": "Reject"
				},
				"6ab81bc6-5e8e-43c5-87b1-84096e76269a": {
					"name": "Approve"
				},
				"027d06cb-7804-4390-bc28-bac4ffd71544": {
					"name": "SequenceFlow11"
				},
				"1e95b087-504b-4626-8c15-da4fc98046c3": {
					"name": "SequenceFlow12"
				},
				"bb111001-0000-0000-0000-000000000001": {
					"name": "SequenceFlow13"
				},
				"bb111002-0000-0000-0000-000000000001": {
					"name": "SequenceFlow14"
				}
			},
			"diagrams": {
				"42fa7a2d-c526-4a02-b3ba-49b5168ba644": {}
			}
		},
		"11a9b5ee-17c0-4159-9bbf-454dcfdcd5c3": {
			"classDefinition": "com.sap.bpm.wfs.StartEvent",
			"id": "startevent1",
			"name": "StartEvent1"
		},
		"2798f4e7-bc42-4fad-a248-159095a2f40a": {
			"classDefinition": "com.sap.bpm.wfs.EndEvent",
			"id": "endevent1",
			"name": "EndEvent1"
		},
		"cc111001-0000-0000-0000-000000000001": {
			"classDefinition": "com.sap.bpm.wfs.ScriptTask",
			"script": "/scripts/leaveApproval/DetermineApprovalLevel.js",
			"reference": "/scripts/leaveApproval/DetermineApprovalLevel.js",
			"id": "scripttask3",
			"name": "Determine Approval Level"
		},
		"cc111004-0000-0000-0000-000000000001": {
			"classDefinition": "com.sap.bpm.wfs.ExclusiveGateway",
			"id": "exclusivegateway2",
			"name": "Approval Level Check",
			"default": "dd111006-0000-0000-0000-000000000001"
		},
		"7b6d4489-4c98-4f87-a72b-accb92aa36fc": {
			"classDefinition": "com.sap.bpm.wfs.UserTask",
			"subject": "Leave Request – ${context.employeeName} | ${context.leaveType} | ${context.startDate} to ${context.endDate}",
			"priority": "MEDIUM",
			"isHiddenInLogForParticipant": false,
			"supportsForward": false,
			"userInterface": "sapui5://comsapbpmworkflow.comsapbpmwusformplayer/com.sap.bpm.wus.form.player",
			"recipientUsers": "${context.managerEmail}",
			"formReference": "/forms/leaveApproval/NewLeaveform.form",
			"userInterfaceParams": [{
				"key": "formId",
				"value": "newleaveform"
			}, {
				"key": "formRevision",
				"value": "1.0"
			}],
			"id": "usertask1",
			"name": "Approve Leave"
		},
		"ff8cf4e2-d9e6-42a5-a004-2f00384f97f2": {
			"classDefinition": "com.sap.bpm.wfs.ExclusiveGateway",
			"id": "exclusivegateway1",
			"name": "RequestDecison",
			"default": "6ab81bc6-5e8e-43c5-87b1-84096e76269a"
		},
		"aa111001-0000-0000-0000-000000000001": {
			"classDefinition": "com.sap.bpm.wfs.ScriptTask",
			"script": "/scripts/leaveApproval/PrepareApprovePayload.js",
			"reference": "/scripts/leaveApproval/PrepareApprovePayload.js",
			"id": "scripttask1",
			"name": "Prepare Approve Payload"
		},
		"aa111002-0000-0000-0000-000000000001": {
			"classDefinition": "com.sap.bpm.wfs.ScriptTask",
			"script": "/scripts/leaveApproval/PrepareRejectPayload.js",
			"reference": "/scripts/leaveApproval/PrepareRejectPayload.js",
			"id": "scripttask2",
			"name": "Prepare Reject Payload"
		},
		"07a00e15-6672-4d38-8080-491fe53c8433": {
			"classDefinition": "com.sap.bpm.wfs.ServiceTask",
			"destination": "hr-sf-emp-data-callback",
			"destinationSource": "consumer",
			"path": "/odata/v4/workflow/approveLeave",
			"httpMethod": "POST",
			"requestVariable": "${context.approvePayload}",
			"id": "servicetask3",
			"name": "Approve"
		},
		"2b1598f9-cb9e-41f4-831c-2c41599118db": {
			"classDefinition": "com.sap.bpm.wfs.ServiceTask",
			"destination": "hr-sf-emp-data-callback",
			"destinationSource": "consumer",
			"path": "/odata/v4/workflow/rejectLeave",
			"httpMethod": "POST",
			"requestVariable": "${context.rejectPayload}",
			"id": "servicetask4",
			"name": "Reject",
			"principalPropagationRef": "7b6d4489-4c98-4f87-a72b-accb92aa36fc"
		},
		"c6b99f32-5fe6-4ab6-b60a-80fba1b9ae0f": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow1",
			"name": "SequenceFlow1",
			"sourceRef": "11a9b5ee-17c0-4159-9bbf-454dcfdcd5c3",
			"targetRef": "cc111001-0000-0000-0000-000000000001"
		},
		"dd111002-0000-0000-0000-000000000001": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow15",
			"name": "SequenceFlow15",
			"sourceRef": "cc111001-0000-0000-0000-000000000001",
			"targetRef": "cc111004-0000-0000-0000-000000000001"
		},
		"dd111005-0000-0000-0000-000000000001": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"condition": "${context.approvalLevel=='AUTO_APPROVE'}",
			"id": "sequenceflow18",
			"name": "AutoApprove",
			"sourceRef": "cc111004-0000-0000-0000-000000000001",
			"targetRef": "aa111001-0000-0000-0000-000000000001"
		},
		"dd111006-0000-0000-0000-000000000001": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow19",
			"name": "ManagerApproval",
			"sourceRef": "cc111004-0000-0000-0000-000000000001",
			"targetRef": "7b6d4489-4c98-4f87-a72b-accb92aa36fc"
		},
		"d268dca6-defb-4e67-9c4e-2b5067271fca": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow2",
			"name": "SequenceFlow2",
			"sourceRef": "7b6d4489-4c98-4f87-a72b-accb92aa36fc",
			"targetRef": "ff8cf4e2-d9e6-42a5-a004-2f00384f97f2"
		},
		"941d5e92-04a7-4264-84b6-4668c01d1cca": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"condition": "${usertasks.usertask1.last.decision=='reject'}",
			"id": "sequenceflow3",
			"name": "Reject",
			"sourceRef": "ff8cf4e2-d9e6-42a5-a004-2f00384f97f2",
			"targetRef": "aa111002-0000-0000-0000-000000000001"
		},
		"6ab81bc6-5e8e-43c5-87b1-84096e76269a": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow10",
			"name": "Approve",
			"sourceRef": "ff8cf4e2-d9e6-42a5-a004-2f00384f97f2",
			"targetRef": "aa111001-0000-0000-0000-000000000001"
		},
		"027d06cb-7804-4390-bc28-bac4ffd71544": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow11",
			"name": "SequenceFlow11",
			"sourceRef": "2b1598f9-cb9e-41f4-831c-2c41599118db",
			"targetRef": "2798f4e7-bc42-4fad-a248-159095a2f40a"
		},
		"1e95b087-504b-4626-8c15-da4fc98046c3": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow12",
			"name": "SequenceFlow12",
			"sourceRef": "07a00e15-6672-4d38-8080-491fe53c8433",
			"targetRef": "2798f4e7-bc42-4fad-a248-159095a2f40a"
		},
		"bb111001-0000-0000-0000-000000000001": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow13",
			"name": "SequenceFlow13",
			"sourceRef": "aa111001-0000-0000-0000-000000000001",
			"targetRef": "07a00e15-6672-4d38-8080-491fe53c8433"
		},
		"bb111002-0000-0000-0000-000000000001": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow14",
			"name": "SequenceFlow14",
			"sourceRef": "aa111002-0000-0000-0000-000000000001",
			"targetRef": "2b1598f9-cb9e-41f4-831c-2c41599118db"
		},
		"42fa7a2d-c526-4a02-b3ba-49b5168ba644": {
			"classDefinition": "com.sap.bpm.wfs.ui.Diagram",
			"symbols": {
				"df898b52-91e1-4778-baad-2ad9a261d30e": {},
				"53e54950-7757-4161-82c9-afa7e86cff2c": {},
				"6bb141da-d485-4317-93b8-e17711df4c32": {},
				"9d0308db-c381-4e31-914a-e57907b18218": {},
				"5e08ddc1-3243-45be-bbb3-9d128e8f4a01": {},
				"a88c1d48-c66c-43ee-b4b2-ae90938d2b8b": {},
				"e3351aa4-4d30-4726-88ea-89e4a5372f14": {},
				"3ec60901-61e2-4f00-ad08-bab630c77e82": {},
				"c079ddf7-9715-4401-a6c0-802a2b63aea9": {},
				"ccae204e-3906-4f7a-8103-69c26148cc75": {},
				"adabd61b-654b-4fd3-833a-aee8ce573f09": {},
				"b02fc9d3-f423-494b-be84-49887fcb0c8a": {},
				"aa111001-0000-0000-0000-000000000002": {},
				"aa111002-0000-0000-0000-000000000002": {},
				"bb111001-0000-0000-0000-000000000002": {},
				"bb111002-0000-0000-0000-000000000002": {},
				"cc111001-0000-0000-0000-000000000002": {},
				"cc111004-0000-0000-0000-000000000002": {},
				"dd111002-0000-0000-0000-000000000002": {},
				"dd111005-0000-0000-0000-000000000002": {},
				"dd111006-0000-0000-0000-000000000002": {}
			}
		},
		"df898b52-91e1-4778-baad-2ad9a261d30e": {
			"classDefinition": "com.sap.bpm.wfs.ui.StartEventSymbol",
			"x": -515.5,
			"y": -324,
			"width": 32,
			"height": 32,
			"object": "11a9b5ee-17c0-4159-9bbf-454dcfdcd5c3"
		},
		"53e54950-7757-4161-82c9-afa7e86cff2c": {
			"classDefinition": "com.sap.bpm.wfs.ui.EndEventSymbol",
			"x": -279,
			"y": 418,
			"width": 35,
			"height": 35,
			"object": "2798f4e7-bc42-4fad-a248-159095a2f40a"
		},
		"6bb141da-d485-4317-93b8-e17711df4c32": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "-498.25,-308 -498.25,-150",
			"sourceSymbol": "df898b52-91e1-4778-baad-2ad9a261d30e",
			"targetSymbol": "cc111001-0000-0000-0000-000000000002",
			"object": "c6b99f32-5fe6-4ab6-b60a-80fba1b9ae0f"
		},
		"9d0308db-c381-4e31-914a-e57907b18218": {
			"classDefinition": "com.sap.bpm.wfs.ui.UserTaskSymbol",
			"x": -287.5,
			"y": -21.7651654539997,
			"width": 100,
			"height": 60,
			"object": "7b6d4489-4c98-4f87-a72b-accb92aa36fc"
		},
		"5e08ddc1-3243-45be-bbb3-9d128e8f4a01": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "-235.75,8.2348345460003 -235.75,142.36741638183594",
			"sourceSymbol": "9d0308db-c381-4e31-914a-e57907b18218",
			"targetSymbol": "a88c1d48-c66c-43ee-b4b2-ae90938d2b8b",
			"object": "d268dca6-defb-4e67-9c4e-2b5067271fca"
		},
		"a88c1d48-c66c-43ee-b4b2-ae90938d2b8b": {
			"classDefinition": "com.sap.bpm.wfs.ui.ExclusiveGatewaySymbol",
			"x": -255,
			"y": 121.36741638183594,
			"object": "ff8cf4e2-d9e6-42a5-a004-2f00384f97f2"
		},
		"e3351aa4-4d30-4726-88ea-89e4a5372f14": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "-234,142.36741638183594 4.5,142.36741638183594 4.5,175",
			"sourceSymbol": "a88c1d48-c66c-43ee-b4b2-ae90938d2b8b",
			"targetSymbol": "aa111002-0000-0000-0000-000000000002",
			"object": "941d5e92-04a7-4264-84b6-4668c01d1cca"
		},
		"3ec60901-61e2-4f00-ad08-bab630c77e82": {
			"classDefinition": "com.sap.bpm.wfs.ui.ServiceTaskSymbol",
			"x": -580,
			"y": 235.36741638183594,
			"width": 100,
			"height": 60,
			"object": "07a00e15-6672-4d38-8080-491fe53c8433"
		},
		"c079ddf7-9715-4401-a6c0-802a2b63aea9": {
			"classDefinition": "com.sap.bpm.wfs.ui.ServiceTaskSymbol",
			"x": -45.5,
			"y": 270,
			"width": 100,
			"height": 60,
			"object": "2b1598f9-cb9e-41f4-831c-2c41599118db"
		},
		"ccae204e-3906-4f7a-8103-69c26148cc75": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "-251.99999167808664,135.50000643730164 -524.999995439782,135.50000643730164",
			"sourceSymbol": "a88c1d48-c66c-43ee-b4b2-ae90938d2b8b",
			"targetSymbol": "aa111001-0000-0000-0000-000000000002",
			"object": "6ab81bc6-5e8e-43c5-87b1-84096e76269a"
		},
		"adabd61b-654b-4fd3-833a-aee8ce573f09": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "0.875,330 0.875,435.5 -254.125,435.5",
			"sourceSymbol": "c079ddf7-9715-4401-a6c0-802a2b63aea9",
			"targetSymbol": "53e54950-7757-4161-82c9-afa7e86cff2c",
			"object": "027d06cb-7804-4390-bc28-bac4ffd71544"
		},
		"b02fc9d3-f423-494b-be84-49887fcb0c8a": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "-530,295.36741638183594 -530,437 -273,437",
			"sourceSymbol": "3ec60901-61e2-4f00-ad08-bab630c77e82",
			"targetSymbol": "53e54950-7757-4161-82c9-afa7e86cff2c",
			"object": "1e95b087-504b-4626-8c15-da4fc98046c3"
		},
		"aa111001-0000-0000-0000-000000000002": {
			"classDefinition": "com.sap.bpm.wfs.ui.ScriptTaskSymbol",
			"x": -575,
			"y": 102,
			"width": 100,
			"height": 60,
			"object": "aa111001-0000-0000-0000-000000000001"
		},
		"aa111002-0000-0000-0000-000000000002": {
			"classDefinition": "com.sap.bpm.wfs.ui.ScriptTaskSymbol",
			"x": -45.5,
			"y": 175,
			"width": 100,
			"height": 60,
			"object": "aa111002-0000-0000-0000-000000000001"
		},
		"bb111001-0000-0000-0000-000000000002": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "-527.5,162 -527.5,235.36741638183594",
			"sourceSymbol": "aa111001-0000-0000-0000-000000000002",
			"targetSymbol": "3ec60901-61e2-4f00-ad08-bab630c77e82",
			"object": "bb111001-0000-0000-0000-000000000001"
		},
		"bb111002-0000-0000-0000-000000000002": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "4.5,235 4.5,270",
			"sourceSymbol": "aa111002-0000-0000-0000-000000000002",
			"targetSymbol": "c079ddf7-9715-4401-a6c0-802a2b63aea9",
			"object": "bb111002-0000-0000-0000-000000000001"
		},
		"cc111001-0000-0000-0000-000000000002": {
			"classDefinition": "com.sap.bpm.wfs.ui.ScriptTaskSymbol",
			"x": -547,
			"y": -180,
			"width": 100,
			"height": 60,
			"object": "cc111001-0000-0000-0000-000000000001"
		},
		"cc111004-0000-0000-0000-000000000002": {
			"classDefinition": "com.sap.bpm.wfs.ui.ExclusiveGatewaySymbol",
			"x": -515,
			"y": -58,
			"object": "cc111004-0000-0000-0000-000000000001"
		},
		"dd111002-0000-0000-0000-000000000002": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "-496.5,-120 -496.5,-34",
			"sourceSymbol": "cc111001-0000-0000-0000-000000000002",
			"targetSymbol": "cc111004-0000-0000-0000-000000000002",
			"object": "dd111002-0000-0000-0000-000000000001"
		},
		"dd111005-0000-0000-0000-000000000002": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "-515,-42 -625.5,-42 -625.5,137 -525,137",
			"sourceSymbol": "cc111004-0000-0000-0000-000000000002",
			"targetSymbol": "aa111001-0000-0000-0000-000000000002",
			"object": "dd111005-0000-0000-0000-000000000001"
		},
		"dd111006-0000-0000-0000-000000000002": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "-494,-16.5 -494,6 -237.5,6",
			"sourceSymbol": "cc111004-0000-0000-0000-000000000002",
			"targetSymbol": "9d0308db-c381-4e31-914a-e57907b18218",
			"object": "dd111006-0000-0000-0000-000000000001"
		},
		"62d7f4ed-4063-4c44-af8b-39050bd44926": {
			"classDefinition": "com.sap.bpm.wfs.LastIDs",
			"sequenceflow": 19,
			"startevent": 1,
			"endevent": 1,
			"usertask": 1,
			"servicetask": 4,
			"scripttask": 3,
			"exclusivegateway": 2
		}
	}
}