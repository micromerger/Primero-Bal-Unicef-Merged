import { Map, List, fromJS } from "immutable";

// import { getUsersByTransitionType } from "../selectors";
import { mountedComponent, screen } from "../../../../test-utils";
import { PrimeroModuleRecord } from "../../../application/records";

import ReassignForm from "./reassign-form";

describe("<ReassignForm />", () => {
  const record = Map({ id: "123abc" });
  const initialState = Map({
    transitions: Map({
      reassign: Map({
        users: List([{ user_name: "primero" }])
      })
    })
  });
  const props = {
    recordType: "cases",
    record,
    handleClose: () => {}
  };

  beforeEach(() => {
    mountedComponent(<ReassignForm {...props} />, initialState);
  });

  it("renders SearchableSelect", () => {
    expect(screen.getByTestId("autocomplete")).toBeInTheDocument();
  });

  it("renders Field", () => {
    expect(document.querySelectorAll(".field")).toHaveLength(2);
  });

  describe("with getUsersByTransitionType", () => {
    describe("when mounting component", () => {
      const state = fromJS({
        records: {
          transitions: {
            reassign: {
              users: [{ user_name: "primero" }, { user_name: "primero_cp" }]
            }
          }
        }
      });
      // const values = getUsersByTransitionType(state, "reassign");

      beforeEach(() => {
        mountedComponent(
          <ReassignForm
            {...{
              record,
              handleClose: () => {},
              recordType: "cases"
            }}
          />,

          state
        );
      });
      // Unit test was skipped pre migration to jest.
      it.skip("should have same no. of users", () => {
        // component.find(ReassignForm).find("input").first().simulate("keyDown", {
        //   key: "ArrowDown",
        //   keyCode: keydown.DOM_VK_DOWN
        // });
        // expect(component.find("div.MuiButtonBase-root.MuiListItem-root")).to.have.lengthOf(values.size);
      });
    });
  });
});

describe("<ReassignForm /> with an overridden incident warning", () => {
  it("renders the overridden warning for an incident linked to a case", () => {
    mountedComponent(
      <ReassignForm recordType="incidents" record={Map({ id: "123abc" })} handleClose={() => {}} formDisabled />,
      fromJS({
        transitions: { reassign: { users: [] } },
        application: {
          modules: [
            PrimeroModuleRecord({
              unique_id: "primeromodule-cp",
              name: "CP",
              field_labels: {
                "reassign.incident_from_case_warning": { en: "You cannot assign this Monitoring Report." }
              }
            })
          ]
        },
        user: { modules: ["primeromodule-cp"] }
      })
    );

    expect(screen.getByText("You cannot assign this Monitoring Report.")).toBeInTheDocument();
  });
});
