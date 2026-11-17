import { fromJS, List } from "immutable";
import { mountedComponent, screen } from "test-utils";

import { PrimeroModuleRecord } from "../application/records";

import { MessageRecord } from "./records";
import Notifier from "./component";

describe("<Notifier />", () => {
  it("renders the overridden message for a translated message key", async () => {
    mountedComponent(
      <Notifier />,
      fromJS({
        application: {
          online: true,
          modules: [
            PrimeroModuleRecord({
              unique_id: "primeromodule-cp",
              name: "CP",
              field_labels: {
                "incident.link_incident_to_case_success": { en: "Linked monitoring report(s) to case" }
              }
            })
          ]
        },
        user: { modules: ["primeromodule-cp"] },
        notifications: List([
          MessageRecord({
            messageKey: "incident.link_incident_to_case_success",
            options: { key: "link-success", variant: "success" }
          })
        ])
      })
    );

    expect(await screen.findByText("Linked monitoring report(s) to case")).toBeInTheDocument();
  });
});
