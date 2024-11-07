import { mountedComponent, screen } from "test-utils";

import { RECORD_TYPES } from "../../../../config";

import FlagForm from "./component";

describe("<FlagForm />", () => {
  const props = {
    recordType: RECORD_TYPES.cases,
    record: "230590",
    handleActiveTab: () => {}
  };

  it("renders Form", () => {
    mountedComponent(<FlagForm {...props} />);
    expect(screen.getAllByText("flags.flag_date")).toHaveLength(2);
  });

  it("should render the FlagForm", () => {
    mountedComponent(<FlagForm {...props} />);
    expect(document.querySelector("#FlagForm")).toBeInTheDocument();
  });
});
