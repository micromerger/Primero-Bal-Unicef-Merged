// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import { expect } from "chai";

import avgOperator from "./avg";

describe("avgOperator", () => {
  const operator = avgOperator(["a", "b", "c"]);
  const decimalPlaceOperator = avgOperator(["a", "b", "c"], { decimalPlaces: 3 });
  const roundOperator = avgOperator(["a", "b", "c"], { decimalPlaces: 0 });

  it("should return avg", () => {
    expect(operator.evaluate({ a: 3, b: 4, c: 2 })).to.deep.equals(3);
  });

  it("should return avg when single argument passed", () => {
    expect(operator.evaluate({ a: 3 })).to.deep.equals(3);
  });

  it("should return 0 when wrong arguments passed", () => {
    expect(operator.evaluate({ d: 3, e: 4 })).to.deep.equals(0);
  });

  it("returns 0 when no argument passed", () => {
    expect(operator.evaluate({})).to.deep.equals(0);
  });
  it("returns a float when decimal places are specified", () => {
    expect(decimalPlaceOperator.evaluate({ a: 1, b: 4 })).to.deep.equals(2.5);
  });
  it("rounds correctly if decimalPlaces are 0", () => {
    expect(roundOperator.evaluate({ a: 1, b: 1, c: 3 })).to.deep.equals(2);
  });
});
