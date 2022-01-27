import { fromJS } from "immutable";

import { tallyFieldForm } from "./tally-field";

describe("tallyFieldForm()", () => {
  const i18n = { t: value => value };
  const formMode = fromJS({
    isNew: false,
    isEdit: true
  });

  it("should return the forms for the Text Field", () => {
    const { forms } = tallyFieldForm({
      field: fromJS({ name: "field_1" }),
      i18n,
      formMode
    });

    expect(forms).to.have.sizeOf(3);
  });
});
