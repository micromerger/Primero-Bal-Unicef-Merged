import { fromJS } from "immutable";

import { mountedComponent, screen } from "../../../test-utils";
import { PrimeroModuleRecord } from "../../application/records";

import OverviewBox from "./component";

describe("<OverviewBox />", () => {
  const props = {
    items: fromJS({
      name: "dashboard.approvals_closure",
      type: "indicator",
      indicators: {
        approval_closure_pending: {
          count: 5,
          query: ["owned_by=primero", "record_state=true", "status=open", "approval_status_closure=pending"]
        }
      }
    }),
    sumTitle: "Closure"
  };

  beforeEach(() => {
    mountedComponent(<OverviewBox {...props} />);
  });

  it("renders a component/>", () => {
    expect(screen.getByText("5 Closure")).toBeInTheDocument();
    expect(screen.getAllByRole("button")).toHaveLength(2);
  });

  describe("when withTotal props is false", () => {
    beforeEach(() => {
      const componentProps = { ...props, withTotal: false };

      mountedComponent(<OverviewBox {...componentProps} />);
    });
    it("renders the header without total/>", () => {
      expect(screen.getByText("Closure")).toBeInTheDocument();
      expect(screen.getAllByRole("button")).toHaveLength(4);
    });
  });

  describe("When data still loading", () => {
    const loadingProps = {
      items: fromJS({
        name: "dashboard.approvals_closure",
        type: "indicator",
        indicators: {}
      }),
      sumTitle: "Closure",
      loading: true
    };

    beforeEach(() => {
      mountedComponent(<OverviewBox {...loadingProps} />);
    });

    it("renders CircularProgress", () => {
      expect(screen.getByRole("progressbar")).toBeInTheDocument();
    });
  });
  describe("When the approvals labels entries are present", () => {
    describe("when is a Assessment approvals", () => {
      const ASSESSMENT_LABEL = "Assessment";
      const propsApprovals = {
        items: fromJS({
          name: "dashboard.approvals_closure",
          type: "indicator",
          indicators: {
            approval_assessment_pending_group: {
              count: 1,
              query: ["record_state=true", "status=open", "approval_status_assessment=pending"]
            }
          }
        }),
        sumTitle: "Pending Approvals"
      };
      const initialState = fromJS({
        application: {
          approvalsLabels: {
            assessment: {
              en: ASSESSMENT_LABEL
            }
          }
        }
      });

      beforeEach(() => {
        mountedComponent(<OverviewBox {...propsApprovals} />, initialState);
      });

      it("renders a component with its respective label />", () => {
        expect(document.querySelectorAll(".overviewList")[1].textContent).toBe(`1${ASSESSMENT_LABEL}`);
      });
    });

    describe("when is GBV Closure approvals", () => {
      const GBV_CLOSURE = "GBV Closure";
      const propsApprovals = {
        items: fromJS({
          name: "dashboard.approvals_gbv_closure",
          type: "indicator",
          indicators: {
            approval_gbv_closure_pending_group: {
              count: 1,
              query: ["record_state=true", "status=open", "approval_status_gbv_closure=pending"]
            }
          }
        }),
        sumTitle: "Pending Approvals"
      };
      const initialState = fromJS({
        application: {
          approvalsLabels: {
            gbv_closure: {
              en: GBV_CLOSURE
            }
          }
        }
      });

      beforeEach(() => {
        mountedComponent(<OverviewBox {...propsApprovals} />, initialState);
      });

      it("renders a component with its respective label />", () => {
        expect(document.querySelectorAll(".overviewList")[1].textContent).toBe(`1${GBV_CLOSURE}`);
      });
    });
  });
});

describe("<OverviewBox /> with overridden indicator labels", () => {
  it("renders the overridden incident indicator labels", () => {
    mountedComponent(
      <OverviewBox
        sumTitle="My Cases / Monitoring Reports"
        withTotal={false}
        items={fromJS({
          name: "dashboard.dash_case_incident_overview",
          type: "indicator",
          indicators: {
            with_incidents: { count: 1, query: ["record_state=true"] },
            with_new_incidents: { count: 2, query: ["record_state=true"] },
            without_incidents: { count: 3, query: ["record_state=true"] }
          }
        })}
      />,
      fromJS({
        application: {
          modules: [
            PrimeroModuleRecord({
              unique_id: "primeromodule-cp",
              name: "CP",
              field_labels: {
                "dashboard.with_incidents": { en: "With Monitoring Reports" },
                "dashboard.with_new_incidents": { en: "With New Monitoring Reports" },
                "dashboard.without_incidents": { en: "Without Monitoring Reports" }
              }
            })
          ]
        },
        user: { modules: ["primeromodule-cp"] }
      })
    );

    expect(screen.getByText("With Monitoring Reports")).toBeInTheDocument();
    expect(screen.getByText("With New Monitoring Reports")).toBeInTheDocument();
    expect(screen.getByText("Without Monitoring Reports")).toBeInTheDocument();
  });
});
