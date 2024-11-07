// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import { spy } from "../../../../test-utils";

import addSubformEntries from "./add-subform-entries";

describe("addSubformEntries", () => {
  it("should execute arrayHelper and setFieldValue", () => {
    const formik = {
      values: {},
      setFieldValue: spy()
    };
    const arrayHelpers = {
      push: spy()
    };
    const values = [
      {
        name: "test"
      }
    ];

    arrayHelpers.push.calledWith(values);
    formik.setFieldValue.calledWith(values);

    addSubformEntries(formik, arrayHelpers, values, true);
  });
});
