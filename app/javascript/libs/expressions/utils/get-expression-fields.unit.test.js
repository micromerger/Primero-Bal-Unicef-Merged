import getExpressionFields from "./get-expression-fields";

describe("getExpressionFields", () => {
  it("returns the field of a comparison expression", () => {
    expect(getExpressionFields({ gt: { age: 17 } })).toEqual(["age"]);
  });

  it("returns the fields of a not_blank expression", () => {
    expect(getExpressionFields({ not_blank: ["a", "b"] })).toEqual(["a", "b"]);
  });

  it("returns the field of a not_blank expression with a single field", () => {
    expect(getExpressionFields({ not_blank: "a" })).toEqual(["a"]);
  });

  it("returns the fields of nested logical expressions", () => {
    const expression = {
      and: [{ not_blank: ["a", "b"] }, { or: [{ eq: { c: 1 } }, { not: { in: { d: ["x"] } } }] }]
    };

    expect(getExpressionFields(expression)).toEqual(["a", "b", "c", "d"]);
  });

  it("returns the fields of a sum expression, ignoring numbers", () => {
    expect(getExpressionFields({ sum: ["a", 2, { sum: ["b"] }] })).toEqual(["a", "b"]);
  });

  it("returns the fields of an avg expression with extra options", () => {
    expect(getExpressionFields({ avg: { data: ["a", "b"], extra: { decimalPlaces: 2 } } })).toEqual(["a", "b"]);
  });

  it("returns the fields of legacy conditions", () => {
    expect(getExpressionFields([{ sex: "male", age: 3 }])).toEqual(["sex", "age"]);
  });

  it("returns each field once", () => {
    expect(getExpressionFields({ and: [{ eq: { a: 1 } }, { not_blank: ["a"] }] })).toEqual(["a"]);
  });
});
