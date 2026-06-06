using ManagerService as service from '../../srv/manager-service';

// ─────────────────────────────────────────────────────────────────────────────
// TeamRequests — Field-level annotations
// ─────────────────────────────────────────────────────────────────────────────
annotate service.TeamRequests with {
    // Hide technical / system fields
    ID                  @UI.Hidden;
    createdAt           @UI.Hidden;
    createdBy           @UI.Hidden;
    modifiedAt          @UI.Hidden;
    modifiedBy          @UI.Hidden;
    criticality         @UI.Hidden;
    approveEnabled      @UI.Hidden;
    rejectEnabled       @UI.Hidden;
    cancelEnabled       @UI.Hidden;

    // Field labels
    employeeName        @title: '{i18n>Employee}';
    department          @title: '{i18n>Department}';
    employeeJobTitle    @title: '{i18n>JobTitle}';
    employeeEmail       @title: '{i18n>Email}';
    leaveTypeName       @title: '{i18n>LeaveType}';
    unitType            @title: '{i18n>Unit}';
    isPaid              @title: '{i18n>PaidLeave}';
    requestManagerName  @title: '{i18n>ApprovingManager}';
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

    // All fields are read-only — manager acts via actions, never edits request fields
    employeeName        @Core.Computed: true;
    department          @Core.Computed: true;
    employeeJobTitle    @Core.Computed: true;
    employeeEmail       @Core.Computed: true;
    leaveTypeName       @Core.Computed: true;
    unitType            @Core.Computed: true;
    isPaid              @Core.Computed: true;
    requestManagerName  @Core.Computed: true;
    numberOfDays        @Core.Computed: true;

    // Approval outcome fields — set by action handlers, never directly editable
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Capabilities — approval is action-only; no field editing or deletion
// ─────────────────────────────────────────────────────────────────────────────
annotate service.TeamRequests with @(
    Capabilities.UpdateRestrictions: { Updatable: false },
    Capabilities.DeleteRestrictions: { Deletable: false }
);

// ─────────────────────────────────────────────────────────────────────────────
// TeamRequests — Main UI layout
// ─────────────────────────────────────────────────────────────────────────────
annotate service.TeamRequests with @(

    // ── List Page header ──────────────────────────────────────────────────────
    UI.HeaderInfo : {
        TypeName       : '{i18n>TeamRequest}',
        TypeNamePlural : '{i18n>TeamRequests}',
        Title          : { $Type : 'UI.DataField', Value : employeeName },
        Description    : { $Type : 'UI.DataField', Value : leaveTypeName },
    },

    // ── Filter bar ────────────────────────────────────────────────────────────
    UI.SelectionFields : [
        status,
        leaveType_code,
        employee_employeeId,
        startDate,
        endDate,
    ],

    // ── List columns ──────────────────────────────────────────────────────────
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Value : employeeName,
            Label : '{i18n>Employee}',
        },
        {
            $Type : 'UI.DataField',
            Value : department,
            Label : '{i18n>Department}',
        },
        {
            $Type : 'UI.DataField',
            Value : leaveTypeName,
            Label : '{i18n>LeaveType}',
        },
        {
            $Type : 'UI.DataField',
            Value : startDate,
        },
        {
            $Type : 'UI.DataField',
            Value : endDate,
        },
        {
            $Type : 'UI.DataField',
            Value : numberOfDays,
        },
        {
            $Type                     : 'UI.DataField',
            Value                     : status,
            Criticality               : criticality,
            CriticalityRepresentation : #WithoutIcon,
        },
        {
            $Type : 'UI.DataField',
            Value : submittedAt,
            Label : '{i18n>SubmittedOn}',
        },
        // Toolbar actions (inline in list)
        {
            $Type  : 'UI.DataFieldForAction',
            Action : 'ManagerService.approve',
            Label  : '{i18n>ActionApprove}',
        },
        {
            $Type  : 'UI.DataFieldForAction',
            Action : 'ManagerService.rejectRequest',
            Label  : '{i18n>ActionReject}',
        },
    ],

    // ── Object Page header action buttons ─────────────────────────────────────
    UI.Identification : [
        {
            $Type  : 'UI.DataFieldForAction',
            Action : 'ManagerService.approve',
            Label  : '{i18n>ActionApprove}',
        },
        {
            $Type  : 'UI.DataFieldForAction',
            Action : 'ManagerService.rejectRequest',
            Label  : '{i18n>ActionReject}',
        },
        {
            $Type  : 'UI.DataFieldForAction',
            Action : 'ManagerService.cancel',
            Label  : '{i18n>ActionCancel}',
        },
    ],

    // ── Object Page — Facets ──────────────────────────────────────────────────
    UI.Facets : [
        {
            $Type  : 'UI.CollectionFacet',
            ID     : 'TeamRequestDetailsFacet',
            Label  : '{i18n>FacetRequestDetails}',
            Facets : [
                {
                    $Type  : 'UI.ReferenceFacet',
                    ID     : 'EmployeeFacet',
                    Label  : '{i18n>FacetEmployee}',
                    Target : '@UI.FieldGroup#Employee',
                },
                {
                    $Type  : 'UI.ReferenceFacet',
                    ID     : 'LeavePeriodFacet',
                    Label  : '{i18n>FacetDates}',
                    Target : '@UI.FieldGroup#Dates',
                },
            ],
        },
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'DecisionFacet',
            Label  : '{i18n>FacetDecision}',
            Target : '@UI.FieldGroup#Decision',
        },
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'HistoryFacet',
            Label  : '{i18n>FacetHistory}',
            Target : 'approvalHistory/@UI.LineItem',
        },
    ],

    // ── Field Groups ──────────────────────────────────────────────────────────

    // Employee & request info — everything the manager needs to make a decision
    UI.FieldGroup #Employee : {
        $Type : 'UI.FieldGroupType',
        Label : '{i18n>FacetEmployee}',
        Data  : [
            { $Type : 'UI.DataField', Value : employeeName,     Label : '{i18n>Employee}' },
            { $Type : 'UI.DataField', Value : department },
            { $Type : 'UI.DataField', Value : employeeJobTitle },
            { $Type : 'UI.DataField', Value : employeeEmail },
            { $Type : 'UI.DataField', Value : leaveTypeName,    Label : '{i18n>LeaveType}' },
            { $Type : 'UI.DataField', Value : isPaid },
            { $Type : 'UI.DataField', Value : requestManagerName },
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

    // Leave period details
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

    // Approval outcome — shows the result of whichever action was taken
    UI.FieldGroup #Decision : {
        $Type : 'UI.FieldGroupType',
        Label : '{i18n>FacetDecision}',
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
// Action availability — controls button visibility/enabled state in Fiori
// ─────────────────────────────────────────────────────────────────────────────
annotate service.TeamRequests actions {

    approve @(
        Core.OperationAvailable            : approveEnabled,
        Common.SideEffects.TargetProperties: [
            'in/status', 'in/approvedBy', 'in/approvedAt', 'in/managerComments',
            'in/criticality', 'in/approveEnabled', 'in/rejectEnabled', 'in/cancelEnabled'
        ]
    );

    rejectRequest @(
        Core.OperationAvailable            : rejectEnabled,
        Common.SideEffects.TargetProperties: [
            'in/status', 'in/rejectedBy', 'in/rejectedAt', 'in/rejectionReason',
            'in/criticality', 'in/approveEnabled', 'in/rejectEnabled', 'in/cancelEnabled'
        ]
    );

    cancel @(
        Core.OperationAvailable            : cancelEnabled,
        Common.SideEffects.TargetProperties: [
            'in/status', 'in/cancelledBy', 'in/cancelledAt', 'in/cancellationReason',
            'in/criticality', 'in/approveEnabled', 'in/rejectEnabled', 'in/cancelEnabled'
        ]
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// ApprovalHistory — sub-table on the Object Page
// ─────────────────────────────────────────────────────────────────────────────
annotate service.ApprovalHistory with @(
    UI.LineItem : [
        { $Type : 'UI.DataField', Value : action,     Label : '{i18n>HistAction}' },
        { $Type : 'UI.DataField', Value : actionBy,   Label : '{i18n>HistActionBy}' },
        { $Type : 'UI.DataField', Value : actionAt,   Label : '{i18n>HistActionAt}' },
        { $Type : 'UI.DataField', Value : fromStatus, Label : '{i18n>HistFromStatus}' },
        { $Type : 'UI.DataField', Value : toStatus,   Label : '{i18n>HistToStatus}' },
        { $Type : 'UI.DataField', Value : comments,   Label : '{i18n>HistComments}' },
    ]
);
