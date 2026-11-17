import { fromJS } from "immutable";

import { COMPARISON_OPERATORS } from "../constants";

import notBlankOperator from "./not-blank";

describe("notBlankOperator", () => {
  const operator = notBlankOperator(["a", "b", "c", "d"]);
  const filledData = { a: "x", b: 0, c: false, d: ["y"] };

  it("returns a not_blank operator", () => {
    expect(operator.operator).toBe(COMPARISON_OPERATORS.NOT_BLANK);
  });

  it("returns true when every field has a value, including 0 and false", () => {
    expect(operator.evaluate(filledData)).toBe(true);
  });

  it("returns false when a field is missing", () => {
    expect(operator.evaluate({ a: "x", b: 0, c: false })).toBe(false);
  });

  it("returns false when a field is null", () => {
    expect(operator.evaluate({ ...filledData, d: null })).toBe(false);
  });

  it("returns false when a field is an empty string", () => {
    expect(operator.evaluate({ ...filledData, d: "" })).toBe(false);
  });

  it("returns false when a field is a whitespace-only string", () => {
    expect(operator.evaluate({ ...filledData, d: "   " })).toBe(false);
  });

  it("returns false when a field is an empty array", () => {
    expect(operator.evaluate({ ...filledData, d: [] })).toBe(false);
  });

  describe("when the data is immutable", () => {
    const immutableOperator = notBlankOperator(["a", "d"]);

    it("returns false when a field is an empty list", () => {
      expect(immutableOperator.evaluate(fromJS({ a: "x", d: [] }))).toBe(false);
    });

    it("returns true when every field has a value", () => {
      expect(immutableOperator.evaluate(fromJS({ a: "x", d: ["y"] }))).toBe(true);
    });
  });

  describe("when a single field is given as a string", () => {
    const singleOperator = notBlankOperator("a");

    it("returns true when the field has a value", () => {
      expect(singleOperator.evaluate({ a: "2026-10-01" })).toBe(true);
    });

    it("returns false when the field is missing", () => {
      expect(singleOperator.evaluate({})).toBe(false);
    });
  });
});
