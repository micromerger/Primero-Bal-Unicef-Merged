import { screen, mountedFieldComponent, fireEvent, waitFor } from "test-utils";

import CheckboxGroup from "./checkbox-group";

describe("form/fields/checkbox-group.jsx", () => {
  const options = [
    { id: 1, display_text: "option-1", tooltip: "option-1.tooltip" },
    { id: 2, display_text: "option-2" }
  ];

  const props = { options, value: [1], onChange: () => {} };

  it("renders checkbox inputs", () => {
    mountedFieldComponent(<CheckboxGroup {...props} />);
    expect(screen.getByText("option-1")).toBeInTheDocument();
  });

  it("renders checkbox inputs with tooltips", async () => {
    mountedFieldComponent(<CheckboxGroup {...props} />);
    fireEvent.mouseOver(screen.getByText("option-1"));
    await waitFor(() => expect(screen.getByText("option-1.tooltip")).toBeInTheDocument());
  });
});
