import { Map, fromJS } from "immutable";

import { mountedComponent, screen } from "../../../../test-utils";
import { PrimeroModuleRecord } from "../../../application/records";

import TransitionDialog from "./transition-dialog";

describe("<TransitionDialog />", () => {
  const record = Map({ case_id_display: "1234abc" });
  const props = {
    open: true,
    transitionType: "referral",
    record,
    children: <></>,
    handleClose: () => {},
    recordType: "cases",
    onClose: () => {},
    successHandler: () => {}
  };

  it("renders Dialog", () => {
    mountedComponent(<TransitionDialog {...props} />);
    expect(screen.getByRole("dialog")).toBeInTheDocument();
  });

  it("renders DialogTitle", () => {
    mountedComponent(<TransitionDialog {...props} />);
    expect(screen.getByText(/transition.type.referral forms.record_types.case 1234abc/)).toBeInTheDocument();
  });

  it("renders DialogContent", () => {
    mountedComponent(<TransitionDialog {...props} />);
    expect(screen.getByText(/transition.type.referral forms.record_types.case 1234abc/)).toBeInTheDocument();
  });

  describe("when transitionType is 'referral'", () => {
    const referralProps = {
      ...props,
      transitionType: "referral"
    };

    it("should render 'Referral Case No.' as title", () => {
      mountedComponent(<TransitionDialog {...referralProps} />);
      expect(screen.getByText(/transition.type.referral forms.record_types.case 1234abc/i)).toBeInTheDocument();
    });
  });

  describe("when transitionType is 'reassign'", () => {
    const reassignProps = {
      ...props,
      transitionType: "reassign"
    };

    it("should render 'Assign Case No.' as title", () => {
      mountedComponent(<TransitionDialog {...reassignProps} />);
      expect(screen.getByText(/transition.type.reassign forms.record_types.case 1234abc/i)).toBeInTheDocument();
    });
  });

  describe("when transitionType is 'Transfer'", () => {
    const reassignProps = {
      ...props,
      transitionType: "transfer"
    };

    it("should render 'Transfer Case No.' as title", () => {
      mountedComponent(<TransitionDialog {...reassignProps} />);
      expect(screen.getByText(/transition.type.transfer forms.record_types.case 1234abc/i)).toBeInTheDocument();
    });
  });

  describe("when the incident record type label is overridden", () => {
    it("renders the overridden record type in the 'Assign Incident' title", () => {
      mountedComponent(
        <TransitionDialog
          {...props}
          transitionType="reassign"
          recordType="incidents"
          record={Map({ incident_code: "abc1234" })}
        />,
        fromJS({
          application: {
            modules: [
              PrimeroModuleRecord({
                unique_id: "primeromodule-cp",
                name: "CP",
                field_labels: { "forms.record_types.incident": { en: "Monitoring Report" } }
              })
            ]
          },
          user: { modules: ["primeromodule-cp"] }
        })
      );

      expect(screen.getByText("transition.type.reassign Monitoring Report abc1234")).toBeInTheDocument();
    });
  });

  describe("when transitionType is 'reassign' for bulk operations", () => {
    const propsForBulk = {
      ...props,
      record: undefined,
      selectedIds: [12345, 67890]
    };

    const reassignBulkProps = {
      ...propsForBulk,
      transitionType: "reassign"
    };

    it("should render 'Assign Cases' as title", () => {
      mountedComponent(<TransitionDialog {...reassignBulkProps} />);
      expect(screen.getByText(/transition.type.reassign forms.record_types.case/i)).toBeInTheDocument();
    });

    it("renders the overridden incident labels in the bulk 'Assign Incidents' dialog", () => {
      mountedComponent(
        <TransitionDialog {...reassignBulkProps} recordType="incidents" selectedRecordsLength={2} />,
        fromJS({
          application: {
            modules: [
              PrimeroModuleRecord({
                unique_id: "primeromodule-cp",
                name: "CP",
                field_labels: {
                  "incidents.label": { en: "Monitoring Reports" },
                  "incidents.selected_records_assign": { en: "%{select_records} monitoring report(s) selected." }
                }
              })
            ]
          },
          user: { modules: ["primeromodule-cp"] }
        })
      );

      expect(screen.getByText(/^transition.type.reassign Monitoring Reports/)).toBeInTheDocument();
      expect(screen.getByText("2 monitoring report(s) selected.")).toBeInTheDocument();
    });
  });
});
