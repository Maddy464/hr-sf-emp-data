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
		"c6b99f32-5fe6-4ab6-b60a-80fba1b9ae0f": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow1",
			"name": "SequenceFlow1",
			"sourceRef": "11a9b5ee-17c0-4159-9bbf-454dcfdcd5c3",
			"targetRef": "7b6d4489-4c98-4f87-a72b-accb92aa36fc"
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
				"bb111002-0000-0000-0000-000000000002": {}
			}
		},
		"df898b52-91e1-4778-baad-2ad9a261d30e": {
			"classDefinition": "com.sap.bpm.wfs.ui.StartEventSymbol",
			"x": 19.5,
			"y": -113,
			"width": 32,
			"height": 32,
			"object": "11a9b5ee-17c0-4159-9bbf-454dcfdcd5c3"
		},
		"53e54950-7757-4161-82c9-afa7e86cff2c": {
			"classDefinition": "com.sap.bpm.wfs.ui.EndEventSymbol",
			"x": 36,
			"y": 575,
			"width": 35,
			"height": 35,
			"object": "2798f4e7-bc42-4fad-a248-159095a2f40a"
		},
		"6bb141da-d485-4317-93b8-e17711df4c32": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "36,-97 36,-34.63637161254883 28,-34.63637161254883 28,41.2348345460003",
			"sourceSymbol": "df898b52-91e1-4778-baad-2ad9a261d30e",
			"targetSymbol": "9d0308db-c381-4e31-914a-e57907b18218",
			"object": "c6b99f32-5fe6-4ab6-b60a-80fba1b9ae0f"
		},
		"62d7f4ed-4063-4c44-af8b-39050bd44926": {
			"classDefinition": "com.sap.bpm.wfs.LastIDs",
			"sequenceflow": 14,
			"startevent": 1,
			"endevent": 1,
			"usertask": 1,
			"scripttask": 2,
			"servicetask": 4,
			"exclusivegateway": 1
		},
		"7b6d4489-4c98-4f87-a72b-accb92aa36fc": {
			"classDefinition": "com.sap.bpm.wfs.UserTask",
			"subject": "Leave Request – ${context.employeeName} | ${context.leaveType} | ${context.startDate} to ${context.endDate}",
			"priority": "MEDIUM",
			"isHiddenInLogForParticipant": false,
			"supportsForward": false,
			"userInterface": "sapui5://comsapbpmworkflow.comsapbpmwusformplayer/com.sap.bpm.wus.form.player",
			"recipientUsers": "${context.managerEmail}",
			"formReference": "/forms/leaveApproval/ApproveLeaveform.form",
			"userInterfaceParams": [{
				"key": "formId",
				"value": "approveleaveform"
			}, {
				"key": "formRevision",
				"value": "1.0"
			}],
			"id": "usertask1",
			"name": "Approve Leave"
		},
		"9d0308db-c381-4e31-914a-e57907b18218": {
			"classDefinition": "com.sap.bpm.wfs.ui.UserTaskSymbol",
			"x": -21.5,
			"y": 11.2348345460003,
			"width": 100,
			"height": 60,
			"object": "7b6d4489-4c98-4f87-a72b-accb92aa36fc"
		},
		"d268dca6-defb-4e67-9c4e-2b5067271fca": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow2",
			"name": "SequenceFlow2",
			"sourceRef": "7b6d4489-4c98-4f87-a72b-accb92aa36fc",
			"targetRef": "ff8cf4e2-d9e6-42a5-a004-2f00384f97f2"
		},
		"5e08ddc1-3243-45be-bbb3-9d128e8f4a01": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "31.25,41.2348345460003 31.25,151.36741638183594",
			"sourceSymbol": "9d0308db-c381-4e31-914a-e57907b18218",
			"targetSymbol": "a88c1d48-c66c-43ee-b4b2-ae90938d2b8b",
			"object": "d268dca6-defb-4e67-9c4e-2b5067271fca"
		},
		"ff8cf4e2-d9e6-42a5-a004-2f00384f97f2": {
			"classDefinition": "com.sap.bpm.wfs.ExclusiveGateway",
			"id": "exclusivegateway1",
			"name": "RequestDecison",
			"default": "6ab81bc6-5e8e-43c5-87b1-84096e76269a"
		},
		"a88c1d48-c66c-43ee-b4b2-ae90938d2b8b": {
			"classDefinition": "com.sap.bpm.wfs.ui.ExclusiveGatewaySymbol",
			"x": 13,
			"y": 130.36741638183594,
			"object": "ff8cf4e2-d9e6-42a5-a004-2f00384f97f2"
		},
		"941d5e92-04a7-4264-84b6-4668c01d1cca": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"condition": "${usertasks.usertask1.last.decision=='reject'}",
			"id": "sequenceflow3",
			"name": "Reject",
			"sourceRef": "ff8cf4e2-d9e6-42a5-a004-2f00384f97f2",
			"targetRef": "aa111002-0000-0000-0000-000000000001"
		},
		"e3351aa4-4d30-4726-88ea-89e4a5372f14": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "34,151.36741638183594 314.5,151.36741638183594 314.5,175",
			"sourceSymbol": "a88c1d48-c66c-43ee-b4b2-ae90938d2b8b",
			"targetSymbol": "aa111002-0000-0000-0000-000000000002",
			"object": "941d5e92-04a7-4264-84b6-4668c01d1cca"
		},
		"6ab81bc6-5e8e-43c5-87b1-84096e76269a": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow10",
			"name": "Approve",
			"sourceRef": "ff8cf4e2-d9e6-42a5-a004-2f00384f97f2",
			"targetRef": "aa111001-0000-0000-0000-000000000001"
		},
		"ccae204e-3906-4f7a-8103-69c26148cc75": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "16.000008321913356,145.00000888109207 -166.99999592111513,144.99999108523417 -167,210",
			"sourceSymbol": "a88c1d48-c66c-43ee-b4b2-ae90938d2b8b",
			"targetSymbol": "aa111001-0000-0000-0000-000000000002",
			"object": "6ab81bc6-5e8e-43c5-87b1-84096e76269a"
		},
		"aa111001-0000-0000-0000-000000000001": {
			"classDefinition": "com.sap.bpm.wfs.ScriptTask",
			"id": "scripttask1",
			"name": "Prepare Approve Payload",
			"script": "/scripts/leaveApproval/PrepareApprovePayload.js"
		},
		"aa111001-0000-0000-0000-000000000002": {
			"classDefinition": "com.sap.bpm.wfs.ui.ScriptTaskSymbol",
			"x": -217,
			"y": 210,
			"width": 100,
			"height": 60,
			"object": "aa111001-0000-0000-0000-000000000001"
		},
		"bb111001-0000-0000-0000-000000000001": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow13",
			"name": "SequenceFlow13",
			"sourceRef": "aa111001-0000-0000-0000-000000000001",
			"targetRef": "07a00e15-6672-4d38-8080-491fe53c8433"
		},
		"bb111001-0000-0000-0000-000000000002": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "-167,270 -167,295.36741638183594",
			"sourceSymbol": "aa111001-0000-0000-0000-000000000002",
			"targetSymbol": "3ec60901-61e2-4f00-ad08-bab630c77e82",
			"object": "bb111001-0000-0000-0000-000000000001"
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
		"3ec60901-61e2-4f00-ad08-bab630c77e82": {
			"classDefinition": "com.sap.bpm.wfs.ui.ServiceTaskSymbol",
			"x": -217,
			"y": 295.36741638183594,
			"width": 100,
			"height": 60,
			"object": "07a00e15-6672-4d38-8080-491fe53c8433"
		},
		"1e95b087-504b-4626-8c15-da4fc98046c3": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow12",
			"name": "SequenceFlow12",
			"sourceRef": "07a00e15-6672-4d38-8080-491fe53c8433",
			"targetRef": "2798f4e7-bc42-4fad-a248-159095a2f40a"
		},
		"b02fc9d3-f423-494b-be84-49887fcb0c8a": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "-167,355.36741638183594 -167,450.4337158203125 42,450.4337158203125 42,594",
			"sourceSymbol": "3ec60901-61e2-4f00-ad08-bab630c77e82",
			"targetSymbol": "53e54950-7757-4161-82c9-afa7e86cff2c",
			"object": "1e95b087-504b-4626-8c15-da4fc98046c3"
		},
		"aa111002-0000-0000-0000-000000000001": {
			"classDefinition": "com.sap.bpm.wfs.ScriptTask",
			"id": "scripttask2",
			"name": "Prepare Reject Payload",
			"script": "/scripts/leaveApproval/PrepareRejectPayload.js"
		},
		"aa111002-0000-0000-0000-000000000002": {
			"classDefinition": "com.sap.bpm.wfs.ui.ScriptTaskSymbol",
			"x": 264.5,
			"y": 175,
			"width": 100,
			"height": 60,
			"object": "aa111002-0000-0000-0000-000000000001"
		},
		"bb111002-0000-0000-0000-000000000001": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow14",
			"name": "SequenceFlow14",
			"sourceRef": "aa111002-0000-0000-0000-000000000001",
			"targetRef": "2b1598f9-cb9e-41f4-831c-2c41599118db"
		},
		"bb111002-0000-0000-0000-000000000002": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "314.5,235 314.5,270",
			"sourceSymbol": "aa111002-0000-0000-0000-000000000002",
			"targetSymbol": "c079ddf7-9715-4401-a6c0-802a2b63aea9",
			"object": "bb111002-0000-0000-0000-000000000001"
		},
		"2b1598f9-cb9e-41f4-831c-2c41599118db": {
			"classDefinition": "com.sap.bpm.wfs.ServiceTask",
			"destination": "hr-sf-emp-data-callback",
			"destinationSource": "consumer",
			"path": "/odata/v4/workflow/rejectLeave",
			"httpMethod": "POST",
			"requestVariable": "${context.rejectPayload}",
			"id": "servicetask4",
			"name": "Reject"
		},
		"c079ddf7-9715-4401-a6c0-802a2b63aea9": {
			"classDefinition": "com.sap.bpm.wfs.ui.ServiceTaskSymbol",
			"x": 264.5,
			"y": 270,
			"width": 100,
			"height": 60,
			"object": "2b1598f9-cb9e-41f4-831c-2c41599118db"
		},
		"027d06cb-7804-4390-bc28-bac4ffd71544": {
			"classDefinition": "com.sap.bpm.wfs.SequenceFlow",
			"id": "sequenceflow11",
			"name": "SequenceFlow11",
			"sourceRef": "2b1598f9-cb9e-41f4-831c-2c41599118db",
			"targetRef": "2798f4e7-bc42-4fad-a248-159095a2f40a"
		},
		"adabd61b-654b-4fd3-833a-aee8ce573f09": {
			"classDefinition": "com.sap.bpm.wfs.ui.SequenceFlowSymbol",
			"points": "314.5,330 314.5,450 57.25,450 57.25,592.5",
			"sourceSymbol": "c079ddf7-9715-4401-a6c0-802a2b63aea9",
			"targetSymbol": "53e54950-7757-4161-82c9-afa7e86cff2c",
			"object": "027d06cb-7804-4390-bc28-bac4ffd71544"
		}
	}
}
