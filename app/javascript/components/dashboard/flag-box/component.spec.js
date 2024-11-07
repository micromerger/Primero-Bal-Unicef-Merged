import { mountedComponent, screen } from "test-utils";
import { fromJS } from "immutable";

import FlagBox from "./component";

describe("<FlagBox />", () => {
  const props = {
    flags: fromJS([
      {
        id: 1,
        name: "User 1",
        date: "2020-12-10",
        message: "Reason 1",
        record_id: "41a3e69b-991a-406e-b0ee-9123cb60c983",
        short_id: "33e620e",
        flagged_by: "primero_test"
      },
      {
        id: 2,
        name: "User 2",
        date: "2020-12-11",
        message: "Reason 3",
        record_id: "41a3e69b-991a-406e-b0ee-9123cb60c973",
        short_id: "33e220e",
        flagged_by: "primero_test"
      }
    ])
  };

  beforeEach(() => {
    mountedComponent(<FlagBox {...props} />);
  });

  it("should render 2 FlagBoxItem", () => {
    expect(screen.getAllByRole("button")).toHaveLength(2);
  });
});
