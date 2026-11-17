import { fromJS, Map, OrderedMap } from "immutable";

import { fireEvent, mountedComponent, screen, waitFor } from "../../../test-utils";
import { FieldRecord, FormSectionRecord } from "../../record-form/records";
import { RECORD_PATH } from "../../../config";
import { PrimeroModuleRecord } from "../../application/records";

import AddIncident from "./component";

describe("<AddIncident />", () => {
  const initialState = Map({
    records: fromJS({
      cases: {
        data: [
          {
            sex: "male",
            created_at: "2020-01-07T14:27:04.136Z",
            name: "G P",
            case_id_display: "96f613f",
            owned_by: "primero_cp",
            status: "open",
            registration_date: "2020-01-07",
            id: "d9df44fb-95d0-4407-91fd-ed18c19be1ad"
          }
        ]
      }
    }),
    forms: Map({
      formSections: OrderedMap({
        1: FormSectionRecord({
          id: 1,
          unique_id: "incident_details_subform_section",
          name: { en: "Nested Incident Details Subform" },
          visible: false,
          is_first_tab: false,
          order: 20,
          order_form_group: 110,
          parent_form: "case",
          editable: true,
          module_ids: [],
          form_group_id: "",
          form_group_name: { en: "Nested Incident Details Subform" },
          fields: [2],
          is_nested: true,
          subform_prevent_item_removal: false,
          collapsed_field_names: ["cp_incident_date", "cp_incident_violence_type"]
        }),
        2: FormSectionRecord({
          id: 2,
          unique_id: "incident_details_container",
          name: { en: "Incident Details" },
          visible: true,
          is_first_tab: false,
          order: 0,
          order_form_group: 30,
          parent_form: "case",
          editable: true,
          module_ids: ["primeromodule-cp"],
          form_group_id: "identification_registration",
          form_group_name: { en: "Identification / Registration" },
          fields: [1],
          is_nested: false,
          subform_prevent_item_removal: false,
          collapsed_field_names: []
        })
      }),
      fields: OrderedMap({
        1: FieldRecord({
          name: "incident_details",
          type: "subform",
          editable: true,
          disabled: false,
          visible: true,
          subform_section_id: 1,
          help_text: { en: "" },
          display_name: { en: "" },
          multi_select: false,
          option_strings_source: null,
          option_strings_text: {},
          guiding_questions: "",
          required: false,
          date_validation: "default_date_validation",
          hide_on_view_page: false,
          date_include_time: false,
          selected_value: "",
          subform_sort_by: "summary_date",
          show_on_minify_form: false
        }),
        2: FieldRecord({
          name: "cp_incident_location_type_other",
          type: "text_field",
          editable: true,
          disabled: false,
          visible: true,
          subform_section_id: null,
          help_text: {},
          multi_select: false,
          option_strings_source: null,
          option_strings_text: {},
          guiding_questions: "",
          required: false,
          date_validation: "default_date_validation",
          hide_on_view_page: false,
          date_include_time: false,
          selected_value: "",
          subform_sort_by: "",
          show_on_minify_form: false
        })
      })
    })
  });
  const props = {
    close: () => {},
    open: true,
    pending: false,
    recordType: RECORD_PATH.cases,
    selectedRowsIndex: [0],
    setPending: () => {}
  };

  it("renders ActionDialog", () => {
    mountedComponent(<AddIncident {...props} />, initialState);
    expect(screen.getByRole("dialog")).toBeInTheDocument();
  });

  it("renders Form", () => {
    mountedComponent(<AddIncident {...props} />, initialState);
    expect(screen.getByText((content, element) => element.tagName.toLowerCase() === "form")).toBeInTheDocument();
  });

  it("renders Fields", () => {
    mountedComponent(<AddIncident {...props} />, initialState);
    expect(screen.queryAllByRole("textbox")).toHaveLength(1);
  });

  it("renders the overridden Add Incident dialog title", () => {
    const stateWithFieldLabels = initialState.setIn(["user", "modules"], fromJS(["primeromodule-cp"])).setIn(
      ["application", "modules"],
      fromJS([
        PrimeroModuleRecord({
          unique_id: "primeromodule-cp",
          name: "CP",
          field_labels: { "actions.incident_details_from_case": { en: "Add Monitoring Report" } }
        })
      ])
    );

    mountedComponent(<AddIncident {...props} />, stateWithFieldLabels);

    expect(screen.getByText("Add Monitoring Report")).toBeInTheDocument();
  });

  it("uses the overridden creation message when saving", async () => {
    const stateWithFieldLabels = initialState.setIn(["user", "modules"], fromJS(["primeromodule-cp"])).setIn(
      ["application", "modules"],
      fromJS([
        PrimeroModuleRecord({
          unique_id: "primeromodule-cp",
          name: "CP",
          field_labels: {
            "incident.messages.creation_success": { en: "Monitoring Report record successfully created." }
          }
        })
      ])
    );

    const { store } = mountedComponent(<AddIncident {...props} />, stateWithFieldLabels);

    fireEvent.click(screen.getByText("buttons.save"));

    await waitFor(() => {
      const messages = store
        .getActions()
        .flatMap(action => action.api?.successCallback || [])
        .map(callback => callback.payload?.message);

      expect(messages).toContain("Monitoring Report record successfully created.");
    });
  });

  describe("when the selected record has a pending transition", () => {
    const pendingProps = { ...props, pendingTransitionIds: ["d9df44fb-95d0-4407-91fd-ed18c19be1ad"] };

    it("shows the pending transition message", () => {
      mountedComponent(<AddIncident {...pendingProps} />, initialState);

      expect(screen.getByText("case.messages.pending_transition_excluded")).toBeInTheDocument();
    });

    it("disables the save button", () => {
      mountedComponent(<AddIncident {...pendingProps} />, initialState);

      expect(screen.getByText("buttons.save").closest("button")).toBeDisabled();
    });
  });
});
