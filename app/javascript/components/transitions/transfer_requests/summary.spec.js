import { mountedComponent, screen } from "../../../test-utils";

import TransferRequestSummary from "./summary";

describe("<TransferRequestSummary />", () => {
  const props = {
    transition: {
      id: "4142488e-ccd9-4ac5-a3c1-c3c0fd063fc8",
      record_id: "6b0018e7-d421-4d6b-80bf-ca4cbf488907",
      record_type: "case",
      created_at: "2019-10-21T16:13:33.890Z",
      notes: "This is a note",
      status: "done",
      type: "TransferRequest",
      consent_overridden: false,
      consent_individual_transfer: true,
      transitioned_by: "primero",
      transitioned_to: "primero_cp"
    },
    classes: {
      wrapper: "wrapperStyle",
      titleHeader: "titleHeaderStyle",
      date: "dateStyle"
    }
  };

  it("renders divs with its corresponding class", () => {
    mountedComponent(<TransferRequestSummary {...props} />);
    expect(screen.getByTestId("wrapper")).toBeInTheDocument();
    expect(screen.getByText("transition.type.transferRequest")).toBeInTheDocument();
    expect(screen.getByTestId("date")).toBeInTheDocument();
  });
});
