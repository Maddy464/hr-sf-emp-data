using LeaveService as service from '../../srv/leave-service';

// ─────────────────────────────────────────────────────────────────────────────
// LeaveRequests — Field-level annotations
// ─────────────────────────────────────────────────────────────────────────────
annotate service.LeaveRequests with {
    // Hide technical / system keys from UI
    ID                  @UI.Hidden;
    createdAt           @UI.Hidden;
    createdBy           @UI.Hidden;
    modifiedAt          @UI.Hidden;
    modifiedBy          @UI.Hidden;
    managerId           @UI.Hidden;
    criticality         @UI.Hidden;
    submitEnabled       @UI.Hidden;
    approveEnabled      @UI.Hidden;
    rejectEnabled       @UI.Hidden;
    cancelEnabled       @UI.Hidden;
    withdrawEnabled     @UI.Hidden;

    // Field labels (map to @Common.Label in OData)
    employee            @title: '{i18n>EmployeeId}';
    leaveType           @title: '{i18n>LeaveTypeCode}';
    startDate           @title: '{i18n>StartDate}';
    endDate             @title: '{i18n>EndDate}';
    numberOfDays        @title: '{i18n>NumberOfDays}';
    halfDayStart        @title: '{i18n>HalfDayStart}';
    halfDayEnd          @title: '{i18n>HalfDayEnd}';
    requestNotes        @title: '{i18n>RequestNotes}'       @UI.MultiLineText;
    status              @title: '{i18n>Status}';
    submittedAt         @title: '{i18n>SubmittedOn}';
    approvedBy          @title: '{i18n>ApprovedBy}';
    approvedAt          @title: '{i18n>ApprovedOn}';
    managerComments     @title: '{i18n>ManagerComments}'    @UI.MultiLineText;
    rejectedBy          @title: '{i18n>RejectedBy}';
    rejectedAt          @title: '{i18n>RejectedOn}';
    rejectionReason     @title: '{i18n>RejectionReason}'   @UI.MultiLineText;
    cancelledBy         @title: '{i18n>CancelledBy}';
    cancelledAt         @title: '{i18n>CancelledOn}';
    cancellationReason  @title: '{i18n>CancellationReason}' @UI.MultiLineText;
    employeeName        @title: '{i18n>Employee}';
    department          @title: '{i18n>Department}';
    requestManager      @title: '{i18n>Manager}';
    requestManagerName  @title: '{i18n>Manager}';
    leaveTypeName       @title: '{i18n>LeaveType}';
    unitType            @title: '{i18n>Unit}';
    isPaid              @title: '{i18n>PaidLeave}';
    requiresAttachment  @title: '{i18n>AttachmentRequired}';

    // ── Read-only: projected fields (server-computed from associations) ────────
    // @Core.Computed renders as display text in both create and edit forms;
    // Fiori Elements will not include these in PATCH/POST payloads.
    employeeName        @Core.Computed: true;
    department          @Core.Computed: true;
    leaveTypeName       @Core.Computed: true;
    unitType            @Core.Computed: true;
    isPaid              @Core.Computed: true;
    requiresAttachment  @Core.Computed: true;

    // Auto-calculated from dates — never directly edited
    numberOfDays        @Core.Computed: true;

    // ── Read-only: Approval Information fields (set by action handlers only) ──
    approvedBy          @Core.Computed: true;
    approvedAt          @Core.Computed: true;
    managerComments     @Core.Computed: true;
    rejectedBy          @Core.Computed: true;
    rejectedAt          @Core.Computed: true;
    rejectionReason     @Core.Computed: true;
    cancelledBy         @Core.Computed: true;
    cancelledAt         @Core.Computed: true;
    cancellationReason  @Core.Computed: true;
    submittedAt         @Core.Computed: true;

    // ── Read-only: employee association (auto-populated from logged-in user) ──
    employee            @Common.FieldControl: #ReadOnly;

    // ── Read-only display text for the designated manager ─────────────────────
    requestManagerName  @Core.Computed: true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Value Helps & Text Associations
// ─────────────────────────────────────────────────────────────────────────────
annotate service.LeaveRequests with {

    // Employee: show fullName, search by employeeId
    employee @(
        Common.Text            : employeeName,
        Common.TextArrangement : #TextOnly,
        Common.ValueList : {
            $Type          : 'Common.ValueListType',
            CollectionPath : 'Employees',
            Parameters     : [
                {
                    $Type             : 'Common.ValueListParameterInOut',
                    LocalDataProperty : employee_employeeId,
                    ValueListProperty : 'employeeId',
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'fullName',
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'department',
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'email',
                },
            ],
        }
    );

    // Leave Type: dropdown (fixed values list — renders as select, not dialog)
    leaveType @(
        Common.Text                 : leaveTypeName,
        Common.TextArrangement      : #TextOnly,
        Common.ValueListWithFixedValues: true,
        Common.ValueList : {
            $Type          : 'Common.ValueListType',
            CollectionPath : 'LeaveTypes',
            Parameters     : [
                {
                    $Type             : 'Common.ValueListParameterInOut',
                    LocalDataProperty : leaveType_code,
                    ValueListProperty : 'code',
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'name',
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'maxDaysPerYear',
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'isPaid',
                },
            ],
        }
    );

    // Approving manager: value help over Employees; editable so user can change it
    requestManager @(
        Common.Text            : requestManagerName,
        Common.TextArrangement : #TextOnly,
        Common.ValueList : {
            $Type          : 'Common.ValueListType',
            CollectionPath : 'Employees',
            Parameters     : [
                {
                    $Type             : 'Common.ValueListParameterInOut',
                    LocalDataProperty : requestManager_employeeId,
                    ValueListProperty : 'employeeId',
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'fullName',
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'department',
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'jobTitle',
                },
            ],
        }
    );

    // Status: dropdown of fixed enum values
    status @(
        Common.ValueListWithFixedValues : true,
        Common.ValueList : {
            $Type          : 'Common.ValueListType',
            CollectionPath : 'LeaveStatus_values',
            Parameters     : [
                {
                    $Type             : 'Common.ValueListParameterInOut',
                    LocalDataProperty : status,
                    ValueListProperty : 'value',
                },
            ],
        }
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// LeaveRequests — Main UI layout
// ─────────────────────────────────────────────────────────────────────────────
annotate service.LeaveRequests with @(

    // ── List Page header ──────────────────────────────────────────────────────
    UI.HeaderInfo : {
        TypeName       : '{i18n>LeaveRequest}',
        TypeNamePlural : '{i18n>LeaveRequests}',
        Title          : { $Type : 'UI.DataField', Value : employeeName },
        Description    : { $Type : 'UI.DataField', Value : leaveTypeName },
    },

    // ── Filter bar fields ─────────────────────────────────────────────────────
    UI.SelectionFields : [
        leaveType_code,
        status,
        startDate,
        endDate,
    ],

    // ── List columns ──────────────────────────────────────────────────────────
    UI.LineItem : [
        {
            $Type       : 'UI.DataField',
            Value       : employeeName,
            Label       : '{i18n>Employee}',
        },
        {
            $Type       : 'UI.DataField',
            Value       : leaveTypeName,
            Label       : '{i18n>LeaveType}',
        },
        {
            $Type       : 'UI.DataField',
            Value       : startDate,
        },
        {
            $Type       : 'UI.DataField',
            Value       : endDate,
        },
        {
            $Type       : 'UI.DataField',
            Value       : numberOfDays,
        },
        {
            $Type                      : 'UI.DataField',
            Value                      : status,
            Criticality                : criticality,
            CriticalityRepresentation  : #WithoutIcon,
        },
        {
            $Type       : 'UI.DataField',
            Value       : submittedAt,
            Label       : '{i18n>SubmittedOn}',
        },
    ],

    // ── Object Page header action buttons ─────────────────────────────────────
    UI.Identification : [
        {
            $Type  : 'UI.DataFieldForAction',
            Action : 'LeaveService.submit',
            Label  : '{i18n>ActionSubmit}',
        },
        {
            $Type  : 'UI.DataFieldForAction',
            Action : 'LeaveService.approve',
            Label  : '{i18n>ActionApprove}',
        },
        {
            $Type  : 'UI.DataFieldForAction',
            Action : 'LeaveService.rejectRequest',
            Label  : '{i18n>ActionReject}',
        },
        {
            $Type  : 'UI.DataFieldForAction',
            Action : 'LeaveService.cancel',
            Label  : '{i18n>ActionCancel}',
        },
        {
            $Type  : 'UI.DataFieldForAction',
            Action : 'LeaveService.withdraw',
            Label  : '{i18n>ActionWithdraw}',
        },
    ],

    // ── Object Page — Facets ──────────────────────────────────────────────────
    UI.Facets : [
        {
            $Type  : 'UI.CollectionFacet',
            ID     : 'LeaveDetailsFacet',
            Label  : '{i18n>FacetLeaveDetails}',
            Facets : [
                {
                    $Type  : 'UI.ReferenceFacet',
                    ID     : 'RequestFacet',
                    Label  : '{i18n>FacetRequest}',
                    Target : '@UI.FieldGroup#Request',
                },
                {
                    $Type  : 'UI.ReferenceFacet',
                    ID     : 'DatesFacet',
                    Label  : '{i18n>FacetDates}',
                    Target : '@UI.FieldGroup#Dates',
                },
            ],
        },
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'ApprovalFacet',
            Label  : '{i18n>FacetApprovalInfo}',
            Target : '@UI.FieldGroup#Approval',
        },
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'HistoryFacet',
            Label  : '{i18n>FacetHistory}',
            Target : 'approvalHistory/@UI.LineItem',
        },
    ],

    // ── Field Groups ──────────────────────────────────────────────────────────
    UI.FieldGroup #Request : {
        $Type : 'UI.FieldGroupType',
        Label : '{i18n>FacetRequest}',
        Data  : [
            // employee: auto-populated, @Common.FieldControl:#ReadOnly locks it
            { $Type : 'UI.DataField', Value : employee_employeeId, Label: '{i18n>Employee}' },
            // department: projected from employee, @Core.Computed renders as text
            { $Type : 'UI.DataField', Value : department },
            // requestManager: auto-populated from employee's manager, editable with value help
            { $Type : 'UI.DataField', Value : requestManager_employeeId, Label: '{i18n>Manager}' },
            // leaveType_code: FK that inherits Common.ValueList + ValueListWithFixedValues → dropdown
            { $Type : 'UI.DataField', Value : leaveType_code },
            { $Type : 'UI.DataField', Value : isPaid },
            { $Type : 'UI.DataField', Value : requiresAttachment },
            {
                $Type                     : 'UI.DataField',
                Value                     : status,
                Criticality               : criticality,
                CriticalityRepresentation : #WithoutIcon,
            },
            { $Type : 'UI.DataField', Value : submittedAt },
            { $Type : 'UI.DataField', Value : requestNotes },
        ],
    },

    UI.FieldGroup #Dates : {
        $Type : 'UI.FieldGroupType',
        Label : '{i18n>FacetDates}',
        Data  : [
            { $Type : 'UI.DataField', Value : startDate },
            { $Type : 'UI.DataField', Value : endDate },
            { $Type : 'UI.DataField', Value : numberOfDays },
            { $Type : 'UI.DataField', Value : halfDayStart },
            { $Type : 'UI.DataField', Value : halfDayEnd },
        ],
    },

    UI.FieldGroup #Approval : {
        $Type : 'UI.FieldGroupType',
        Label : '{i18n>FacetApprovalInfo}',
        Data  : [
            { $Type : 'UI.DataField', Value : approvedBy },
            { $Type : 'UI.DataField', Value : approvedAt },
            { $Type : 'UI.DataField', Value : managerComments },
            { $Type : 'UI.DataField', Value : rejectedBy },
            { $Type : 'UI.DataField', Value : rejectedAt },
            { $Type : 'UI.DataField', Value : rejectionReason },
            { $Type : 'UI.DataField', Value : cancelledBy },
            { $Type : 'UI.DataField', Value : cancelledAt },
            { $Type : 'UI.DataField', Value : cancellationReason },
        ],
    },
);

// ─────────────────────────────────────────────────────────────────────────────
// Side effects — triggers a server read of numberOfDays after any date change.
// The before('UPDATE') handler in leave-service.js recalculates the value;
// these annotations tell Fiori Elements to refresh numberOfDays in the form.
// ─────────────────────────────────────────────────────────────────────────────
annotate service.LeaveRequests with @(
    Common.SideEffects #OnDateChange : {
        $Type            : 'Common.SideEffectsType',
        SourceProperties : [startDate, endDate, halfDayStart, halfDayEnd],
        TargetProperties : [numberOfDays]
    },
    Common.SideEffects #OnManagerChange : {
        $Type            : 'Common.SideEffectsType',
        SourceProperties : [requestManager_employeeId],
        TargetProperties : [requestManagerName]
    }
);

// ─────────────────────────────────────────────────────────────────────────────
// Action availability — controls button enabled/disabled state in Fiori
// ─────────────────────────────────────────────────────────────────────────────
// Simple path references — false → HIDDEN on Object Page (UI.Identification),
// DISABLED on List Report toolbar (UI.LineItem). No $edmJson needed.
annotate service.LeaveRequests actions {

    submit @(
        Core.OperationAvailable            : submitEnabled,
        Common.SideEffects.TargetProperties: [
            'in/status', 'in/submittedAt', 'in/criticality',
            'in/submitEnabled', 'in/approveEnabled', 'in/rejectEnabled',
            'in/cancelEnabled', 'in/withdrawEnabled'
        ]
    );

    approve @(
        Core.OperationAvailable            : approveEnabled,
        Common.SideEffects.TargetProperties: [
            'in/status', 'in/approvedBy', 'in/approvedAt', 'in/managerComments',
            'in/criticality', 'in/approveEnabled', 'in/rejectEnabled',
            'in/cancelEnabled', 'in/withdrawEnabled'
        ]
    );

    rejectRequest @(
        Core.OperationAvailable            : rejectEnabled,
        Common.SideEffects.TargetProperties: [
            'in/status', 'in/rejectedBy', 'in/rejectedAt', 'in/rejectionReason',
            'in/criticality', 'in/approveEnabled', 'in/rejectEnabled',
            'in/cancelEnabled', 'in/withdrawEnabled'
        ]
    );

    cancel @(
        Core.OperationAvailable            : cancelEnabled,
        Common.SideEffects.TargetProperties: [
            'in/status', 'in/cancelledBy', 'in/cancelledAt',
            'in/criticality', 'in/submitEnabled', 'in/cancelEnabled',
            'in/approveEnabled', 'in/rejectEnabled'
        ]
    );

    withdraw @(
        Core.OperationAvailable            : withdrawEnabled,
        Common.SideEffects.TargetProperties: [
            'in/status', 'in/cancelledBy', 'in/cancelledAt',
            'in/criticality', 'in/withdrawEnabled', 'in/submitEnabled'
        ]
    );
};

// ─────────────────────────────────────────────────────────────────────────────
// ApprovalHistory — sub-table on Object Page
// ─────────────────────────────────────────────────────────────────────────────
annotate service.ApprovalHistory with {
    ID      @UI.Hidden;
    request @UI.Hidden;
    action     @title: '{i18n>HistAction}';
    actionBy   @title: '{i18n>HistActionBy}';
    actionAt   @title: '{i18n>HistActionAt}';
    comments   @title: '{i18n>HistComments}';
    fromStatus @title: '{i18n>HistFromStatus}';
    toStatus   @title: '{i18n>HistToStatus}';
}

annotate service.ApprovalHistory with @(
    UI.LineItem : [
        { $Type : 'UI.DataField', Value : actionAt },
        { $Type : 'UI.DataField', Value : action },
        { $Type : 'UI.DataField', Value : actionBy },
        { $Type : 'UI.DataField', Value : fromStatus },
        { $Type : 'UI.DataField', Value : toStatus },
        { $Type : 'UI.DataField', Value : comments },
    ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Employees — for value help display
// ─────────────────────────────────────────────────────────────────────────────
annotate service.Employees with {
    employeeId  @title: '{i18n>EmployeeId}';
    fullName    @title: '{i18n>FullName}';
    email       @title: '{i18n>Email}';
    department  @title: '{i18n>Department}';
    jobTitle    @title: '{i18n>JobTitle}';
}

// ─────────────────────────────────────────────────────────────────────────────
// LeaveTypes — for value help display
// ─────────────────────────────────────────────────────────────────────────────
annotate service.LeaveTypes with {
    code            @title: '{i18n>Code}';
    name            @title: '{i18n>LeaveType}';
    unitType        @title: '{i18n>Unit}';
    isPaid          @title: '{i18n>PaidLeave}';
    maxDaysPerYear  @title: '{i18n>MaxDaysPerYear}';
}
