// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import getSelectFieldDefaultValue from "./get-select-field-default-value";

describe("getSelectFieldDefaultValue", () => {
  context("when the selectedDefaultValue is null", () => {
    it("should return the selected default value for multi_select", () => {
      expect(getSelectFieldDefaultValue({ multi_select: true }, null)).to.deep.equal([]);
    });

    it("should return the selected default value for multi_select", () => {
      expect(getSelectFieldDefaultValue({ multi_select: true }, "")).to.deep.equal([]);
    });

    it("should return the selected default value for single select", () => {
      expect(getSelectFieldDefaultValue({}, null)).to.be.null;
    });
  });
});
