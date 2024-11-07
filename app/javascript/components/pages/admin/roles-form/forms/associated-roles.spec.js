// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import { fromJS } from "immutable";

import AssociatedRolesForm from "./associated-roles";

describe("pages/admin/<RolesForm>/forms - AssociatedRolesForm", () => {
  const i18n = { t: () => "" };

  it("returns the AssociatedRolesForm with fields", () => {
    const roleForms = AssociatedRolesForm(fromJS([]), i18n);

    expect(roleForms.fields).toHaveLength(2);
  });
});
