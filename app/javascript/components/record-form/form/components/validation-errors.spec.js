// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import { fromJS } from "immutable";

import { mountedComponent } from "../../../../test-utils";
import { ENQUEUE_SNACKBAR } from "../../../notifier";

import ValidationErrors from "./validation-errors";

describe("<ValidationErrors />", () => {
  const initialState = fromJS({ forms: {} });

  it("dispatches a snackbar notification when the form has errors", () => {
    const { store } = mountedComponent(
      <ValidationErrors
        {...{
          forms: fromJS([{ unique_id: "form_1" }]),
          formErrors: { field_1: "This field is required" },
          submitCount: 1
        }}
      />,
      initialState
    );

    expect(store.getActions().filter(action => action.type === ENQUEUE_SNACKBAR)).toHaveLength(1);
  });

  it("should not dispatch a snackbar notification if subform does not have error", () => {
    const { store } = mountedComponent(
      <ValidationErrors
        {...{
          forms: fromJS([{ unique_id: "form_1" }]),
          formErrors: { subform_section_1: [] }
        }}
      />,
      initialState
    );

    expect(store.getActions().filter(action => action.type === ENQUEUE_SNACKBAR)).toHaveLength(0);
  });
});
