import { fromJS, OrderedMap } from "immutable";
import { fireEvent, mountedComponent, screen } from "test-utils";

import { PrimeroModuleRecord } from "../application/records";
import { FormSectionRecord } from "../record-form/records";

import CaseRegistry from "./component";

describe("<CaseRegistry />", () => {
  const props = {
    values: {},
    primeroModule: "primeromodule-cp",
    mobileDisplay: false,
    handleToggleNav: () => {},
    mode: { isEdit: true, isShow: false },
    recordType: "case",
    setFieldValue: () => {}
  };

  const initialState = fromJS({
    application: {
      modules: [
        PrimeroModuleRecord({
          unique_id: "primeromodule-cp",
          name: "CP",
          associated_record_types: ["case", "registry_record"],
          field_labels: {
            "navigation.registry_records": { en: "CBCRCs" },
            "forms.record_types.registry_details": { en: "CBCRC Details" }
          }
        })
      ]
    },
    forms: { formSections: {} },
    records: { registry_records: { data: [] } },
    user: {
      modules: ["primeromodule-cp"],
      permissions: { cases: ["add_registry_record", "view_registry_record"] }
    }
  });

  beforeEach(() => {
    jest
      .spyOn(window.I18n, "t")
      .mockImplementation((path, options) => (options?.record_type ? `${path}: ${options.record_type}` : path));
  });

  it("renders the overridden registry details form name", () => {
    mountedComponent(<CaseRegistry {...props} mode={{ isEdit: false, isShow: true }} />, initialState);

    expect(screen.getByRole("heading", { level: 3, name: "CBCRC Details" })).toBeInTheDocument();
    expect(screen.queryByText("forms.record_types.registry_details")).not.toBeInTheDocument();
  });

  it("renders the overridden registry label in the search drawer title", async () => {
    mountedComponent(<CaseRegistry {...props} />, initialState);

    fireEvent.click(screen.getByText("case.add_new"));

    expect(await screen.findByText("case.search_for: CBCRCs")).toBeInTheDocument();
  });

  it("falls back to the overridden registry label when the configured form has no registry type", async () => {
    const stateWithConfiguredForm = initialState.setIn(
      ["forms", "formSections"],
      OrderedMap({
        1: FormSectionRecord({
          id: 1,
          unique_id: "registry_from_case",
          parent_form: "case",
          module_ids: ["primeromodule-cp"],
          visible: true,
          name: { en: "CBCRC Details" },
          fields: []
        })
      })
    );

    mountedComponent(<CaseRegistry {...props} />, stateWithConfiguredForm);

    fireEvent.click(screen.getByText("case.add_new"));

    expect(await screen.findByText("case.search_for: CBCRCs")).toBeInTheDocument();
  });
});
