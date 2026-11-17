import { RECORD_PATH } from "../../../config";

import buildActionList from "./build-action-list";

describe("record-actions/utils/build-action-list", () => {
  const i18n = {
    t: t => t
  };

  const requestsApproval = [
    {
      name: "SER",
      condition: true,
      recordType: "all",
      value: "assessment"
    },
    {
      name: "Case Plan",
      condition: true,
      recordType: "all",
      value: "case_plan"
    }
  ];

  const approvals = [
    {
      name: "SER",
      condition: false,
      recordType: "all",
      value: "assessment"
    },
    {
      name: "Case Plan",
      condition: false,
      recordType: "all",
      value: "case_plan"
    }
  ];

  it("should be a function", () => {
    expect(buildActionList).toBeInstanceOf(Function);
  });

  it("should return the actionlist", () => {
    const params = {
      approvals,
      canAddIncident: true,
      hasIncidentSubform: true,
      canAddNotes: true,
      canAddService: true,
      hasServiceSubform: true,
      canApprove: false,
      canAssign: true,
      canCreateIncident: false,
      canEnable: false,
      canAttributeCase: false,
      canOnlyExportPdf: true,
      canOpenOrClose: false,
      canRefer: false,
      canRequest: true,
      canShowExports: true,
      canTransfer: false,
      dispatch: () => {},
      enableState: "enable",
      handleDialogClick: () => {},
      i18n,
      isIdSearch: false,
      isShow: true,
      openState: "reopen",
      recordType: "cases",
      requestsApproval,
      showListAction: true
    };

    const response = buildActionList(params);

    expect(Object.keys(response).length).toBe(2);
    expect(response.actions.length).toBe(4);
    expect(Object.keys(response.dialogs)).toEqual([
      "referral",
      "assign",
      "transfer",
      "openClose",
      "enableDisable",
      "incidentDialog",
      "serviceDialog",
      "notes",
      "requestApproval",
      "approve",
      "export",
      "markForOffline",
      "bulkFlag",
      "linkIncidentToCase",
      "attributeCase"
    ]);
  });

  describe("when is assign for Incident", () => {
    it("should return the actionlist", () => {
      const params = {
        recordType: RECORD_PATH.incidents,
        i18n,
        requestsApproval,
        approvals,
        enableState: "enable",
        canAddIncident: false,
        canAddNotes: false,
        canAddService: false,
        canApprove: false,
        canAssign: true,
        canCreateIncident: false,
        canEnable: false,
        canOnlyExportPdf: false,
        canOpenOrClose: false,
        canRefer: false,
        canRequest: false,
        canShowExports: true,
        canTransfer: false,
        canMarkForOffline: false
      };

      const response = buildActionList(params);

      expect(response.actions.map(action => action.name)).toEqual([
        "buttons.reassign forms.record_types.incident",
        "actions.enable",
        "incidents.export",
        "incident.link_incident_to_case"
      ]);
    });
  });

  describe("when the incident labels are overridden", () => {
    const overrides = {
      "forms.record_types.incident": "Monitoring Report",
      "actions.incident_from_case": "Create Monitoring Report",
      "incident.link_incident_to_case": "Link Monitoring Report to Case",
      "actions.incident_details_from_case": "Add Monitoring Report"
    };
    const label = key => overrides[key] || key;

    it("uses the overridden labels for the incident actions", () => {
      const response = buildActionList({
        recordType: RECORD_PATH.incidents,
        i18n,
        label,
        requestsApproval,
        approvals,
        enableState: "enable",
        canAssign: true,
        canShowExports: true
      });

      expect(response.actions.map(action => action.name)).toEqual([
        "buttons.reassign Monitoring Report",
        "actions.enable",
        "incidents.export",
        "Link Monitoring Report to Case"
      ]);
    });

    it("uses the overridden label for the create incident action", () => {
      const response = buildActionList({
        recordType: RECORD_PATH.cases,
        i18n,
        label,
        requestsApproval,
        approvals,
        canCreateIncident: true,
        isShow: true
      });

      expect(response.actions.map(action => action.name)).toContain("Create Monitoring Report");
    });

    it("uses the overridden label for the add incident action", () => {
      const response = buildActionList({
        recordType: RECORD_PATH.cases,
        i18n,
        label,
        requestsApproval,
        approvals,
        canAddIncident: true,
        hasIncidentSubform: true,
        showListActions: true
      });

      expect(response.actions.map(action => action.name)).toContain("Add Monitoring Report");
    });
  });
});
