// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import { mountedComponent, screen } from "test-utils";

import DefaultEditActions from "./component";

describe("<RecordForm>/form/subforms/subform-fields/<DefaultEditActions>", () => {
  describe("when is incident actions", () => {
    it("should render back to violations button", () => {
      mountedComponent(
        <DefaultEditActions
          handleBackLabel="incident.violation.back_to_violations"
          handleBack={() => {}}
          handleCancel={() => {}}
        />
      );

      expect(screen.queryByText("incident.violation.back_to_violations")).toBeTruthy();
      expect(screen.queryByText("cancel")).toBeTruthy();
    });
  });
});
