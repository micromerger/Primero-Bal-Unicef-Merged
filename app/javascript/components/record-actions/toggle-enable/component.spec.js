import { fromJS } from "immutable";
import { fireEvent, mountedComponent, screen } from "test-utils";

import { PrimeroModuleRecord } from "../../application/records";

import ToggleEnable from "./component";

describe("<ToggleEnable />", () => {
  const props = {
    close: () => {},
    open: true,
    record: fromJS({ id: "e25c5cb1-1257-472e-b2ec-05f568a3b51e", record_state: true }),
    recordType: "incidents"
  };

  const state = fromJS({
    application: {
      modules: [
        PrimeroModuleRecord({
          unique_id: "primeromodule-cp",
          name: "CP",
          field_labels: {
            "incidents.disable_dialog_title": { en: "Disable Monitoring Report" },
            "incidents.disable_dialog": {
              en: "Clicking OK will change the status of this monitoring report to Disabled."
            },
            "incidents.disable_success": { en: "Successfully disabled monitoring report" }
          }
        })
      ]
    },
    user: { modules: ["primeromodule-cp"] }
  });

  it("renders the overridden disable dialog title and text", () => {
    mountedComponent(<ToggleEnable {...props} />, state);

    expect(screen.getByText("Disable Monitoring Report")).toBeInTheDocument();
    expect(
      screen.getByText("Clicking OK will change the status of this monitoring report to Disabled.")
    ).toBeInTheDocument();
  });

  it("uses the overridden success message", () => {
    const { store } = mountedComponent(<ToggleEnable {...props} />, state);

    fireEvent.click(screen.getByText("cases.ok"));

    const messages = store
      .getActions()
      .flatMap(action => action.api?.successCallback || [])
      .map(callback => callback.payload?.message);

    expect(messages).toContain("Successfully disabled monitoring report");
  });
});
