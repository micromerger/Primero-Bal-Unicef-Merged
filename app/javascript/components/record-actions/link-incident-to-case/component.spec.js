import { fromJS } from "immutable";
import { mountedComponent, screen } from "test-utils";

import { PrimeroModuleRecord } from "../../application/records";

import LinkIncidentToCase from "./component";

describe("<LinkIncidentToCase />", () => {
  const props = {
    close: () => {},
    open: true, // Assuming the component should start in an open state
    currentPage: 1, // Example value
    selectedRecords: {}, // Example value
    clearSelectedRecords: () => {},
    recordType: "cases" // Example value
  };

  beforeEach(() => {
    mountedComponent(<LinkIncidentToCase {...props} />);
  });

  it("renders  Action Dialog", () => {
    expect(screen.getByText("incident.link_incident_to_case")).toBeInTheDocument();
  });

  it("render Form", () => {
    expect(screen.getByTestId("search-form-for-link-to-case")).toBeInTheDocument();
  });

  it("render Table", () => {
    expect(screen.getByRole("grid")).toBeInTheDocument();
  });

  it("render Table and havig data", () => {
    expect(screen.getByText("potential_match.case_id")).toBeInTheDocument();
  });
});

describe("<LinkIncidentToCase /> with an overridden label", () => {
  it("renders the overridden title", () => {
    mountedComponent(
      <LinkIncidentToCase
        close={() => {}}
        open
        currentPage={1}
        selectedRecords={{}}
        clearSelectedRecords={() => {}}
        recordType="incidents"
      />,
      fromJS({
        application: {
          modules: [
            PrimeroModuleRecord({
              unique_id: "primeromodule-cp",
              name: "CP",
              field_labels: { "incident.link_incident_to_case": { en: "Link Monitoring Report to Case" } }
            })
          ]
        },
        user: { modules: ["primeromodule-cp"] }
      })
    );

    expect(screen.getByText("Link Monitoring Report to Case")).toBeInTheDocument();
  });
});
