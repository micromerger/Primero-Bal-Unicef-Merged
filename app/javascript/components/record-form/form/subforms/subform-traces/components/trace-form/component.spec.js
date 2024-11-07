// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.
import { mountedFormComponent, screen } from "../../../../../../../test-utils";
import { FormSectionRecord, FieldRecord } from "../../../../../records";
import { TEXT_FIELD } from "../../../../../constants";

import TracesForm from "./component";

describe("<RecordForm>/form/subforms/<TracesForm>", () => {
  const props = {
    handleBack: () => {},
    traceValues: {},
    formSection: FormSectionRecord({
      fields: [FieldRecord({ type: TEXT_FIELD, name: "test_field" })],
      setIn: () => {}
    }),
    handleConfirm: () => {},
    mode: { isEdit: false }
  };

  it("should render the TraceActions", () => {
    mountedFormComponent(<TracesForm {...props} />);
    expect(screen.getByTestId("trace-actions")).toBeInTheDocument();
  });

  it("should render a FormSection", () => {
    mountedFormComponent(<TracesForm {...props} />);
    expect(screen.getByRole("textbox")).toBeInTheDocument();
  });
});
