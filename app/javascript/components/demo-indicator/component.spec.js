import { mountedComponent, screen } from "test-utils";

import { DEMO } from "../application/constants";

import DemoIndicator from "./component";

describe("<DemoIndicator />", () => {
  const props = {
    isDemo: false
  };

  it("when isDemo is false it should return null", () => {
    const { container } = mountedComponent(<DemoIndicator {...props} />);

    expect(container).toBeEmptyDOMElement();
  });

  it("when isDemo is true it should return an Alert with 'Demo' text", () => {
    const newProps = {
      isDemo: true
    };

    mountedComponent(<DemoIndicator {...newProps} />);
    const element = screen.getByText(DEMO);

    expect(element).toBeInTheDocument();
  });
});
