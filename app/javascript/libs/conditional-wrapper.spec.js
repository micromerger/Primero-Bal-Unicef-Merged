import { Tooltip } from "@mui/material";
import { simpleMountedComponent, screen, fireEvent, waitFor } from "test-utils";

import { ConditionalWrapper } from "./conditional-wrapper";

describe("libs/conditional-wrapper", () => {
  const wrapper = ({ children, text }) => (
    <div>
      {text}
      {children}
    </div>
  );

  it("wraps component with props if condition true", () => {
    simpleMountedComponent(
      <ConditionalWrapper condition wrapper={wrapper} text="wrapper content">
        <div>wrapped children</div>
      </ConditionalWrapper>
    );

    expect(screen.getByText(/wrapped children/i)).toBeInTheDocument();
    expect(screen.getByText(/wrapper content/i)).toBeInTheDocument();
  });

  it("does not wrap component if condition false", () => {
    simpleMountedComponent(
      <ConditionalWrapper condition={false} wrapper={wrapper} text="wrapper content">
        <div>wrapped children</div>
      </ConditionalWrapper>
    );

    expect(screen.getByText(/wrapped children/i)).toBeInTheDocument();
    expect(screen.queryByText(/wrapper content/i)).toBeNull();
  });

  it("renders react components", async () => {
    simpleMountedComponent(
      <ConditionalWrapper condition wrapper={Tooltip} title="wrapper content">
        <div>wrapped children</div>
      </ConditionalWrapper>
    );

    fireEvent.mouseOver(screen.getByText(/wrapped children/i));
    await waitFor(() => expect(screen.queryByText(/wrapper content/i)).toBeInTheDocument());

    expect(screen.getByText(/wrapped children/i)).toBeInTheDocument();
  });
});
