// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import { fromJS } from "immutable";

import { setupHook } from "../../test-utils";

import { OPTION_TYPES } from "./constants";
import useOptions from "./use-options";

describe("Forms - useOptions", () => {
  const lookup2 = { unique_id: "lookup-2", name: { en: "Lookup 2" } };
  const referToUsers = [
    {
      id: 1,
      user_name: "test_1"
    },
    {
      id: 2,
      user_name: "test_2"
    },
    {
      id: 3,
      user_name: "test_3"
    }
  ];

  const roles = [
    {
      id: 1,
      unique_id: "role-1",
      name: "Role 1",
      referral: true,
      form_section_unique_ids: ["test-1"]
    },
    {
      id: 2,
      unique_id: "role-2",
      name: "Role 2",
      referral: false,
      form_section_unique_ids: ["test-1", "test-2"]
    }
  ];

  const agencies = [
    { id: 1, name: { en: "Agency 1" } },
    { id: 2, name: { en: "Agency 2" } }
  ];

  const stateWithLookups = fromJS({
    records: {
      transitions: {
        referral: {
          users: referToUsers
        }
      }
    },
    forms: {
      options: {
        lookups: [
          {
            unique_id: "lookup-1",
            name: { en: "Lookup 1" }
          },
          lookup2
        ]
      }
    },
    application: {
      agencies,
      managedRoles: roles,
      roles
    },
    user: {
      agencyId: 1,
      permittedRoleUniqueIds: ["role-1"]
    }
  });

  it("should return all lookup types including customs", () => {
    const { result } = setupHook(() => useOptions({ source: OPTION_TYPES.LOOKUPS }), stateWithLookups);

    expect(result.current).toStrictEqual([
      {
        id: "lookup lookup-1",
        display_text: "Lookup 1",
        values: []
      },
      {
        id: "lookup lookup-2",
        display_text: "Lookup 2",
        values: []
      },
      {
        id: "Agency",
        display_text: "agency.label",
        translate: true
      },
      {
        display_text: "linkedincidents.label",
        id: "LinkedIncidents",
        translate: true
      },
      {
        id: "Location",
        display_text: "location.label",
        translate: true
      },
      {
        id: "User",
        display_text: "user.label",
        translate: true
      }
    ]);
  });

  it("should return the options for optionStringsText", () => {
    const optionStringsText = [
      { id: "submitted", display_text: "Submitted" },
      { id: "pending", display_text: "Pending" },
      { id: "no", display_text: "No" }
    ];
    const expected = optionStringsText;
    const { result } = setupHook(() => useOptions({ options: optionStringsText }), stateWithLookups);

    expect(result.current).toStrictEqual(expected);
  });

  it("should return the options, even if we includes other keys that are not id or display_text", () => {
    const optionStringsText = [
      { id: "submitted", display_text: "Submitted", tooltip: "Submitted tooltip" },
      { id: "pending", display_text: "Pending", tooltip: "Pending tooltip" },
      { id: "no", display_text: "No", tooltip: "No tooltip" }
    ];
    const expected = optionStringsText;
    const { result } = setupHook(() => useOptions({ options: optionStringsText }), stateWithLookups);

    expect(result.current).toStrictEqual(expected);
  });

  it("returns the options with tags if the tags are present", () => {
    const stateWithTags = fromJS({
      forms: {
        options: {
          lookups: [
            {
              unique_id: "lookup-1",
              name: { en: "Lookup 1" },
              values: [{ id: "option1", display_text: { en: "Option 1" }, tags: ["low"] }]
            },
            lookup2
          ]
        }
      }
    });
    const { result } = setupHook(() => useOptions({ source: "lookup lookup-1" }), stateWithTags);

    expect(result.current).toStrictEqual([{ id: "option1", display_text: "Option 1", disabled: false, tags: ["low"] }]);
  });

  describe("getFormGroupLookups", () => {
    const lookups = [
      {
        unique_id: "lookup-form-group-cp-case",
        name: { en: "Lookup 1" },
        values: []
      },
      {
        unique_id: "lookup-form-group-cp-incident",
        name: { en: "Lookup 2" },
        values: []
      },
      {
        unique_id: "lookup-form-group-gbv-incident",
        name: { en: "Lookup 3" },
        values: []
      }
    ];
    const stateWithLookupsFormGroup = fromJS({
      forms: {
        options: {
          lookups
        }
      }
    });

    it("should return formGroups lookups", () => {
      const source = "FormGroupLookup";
      const { result } = setupHook(() => useOptions({ source }), stateWithLookupsFormGroup);

      expect(result.current).toStrictEqual(lookups);
    });
  });

  describe("when source is violations", () => {
    it("should return options for violations", () => {
      const source = "violations";
      const options = [
        { id: 1, display_text: "test1" },
        { id: 2, display_text: "test2" }
      ];
      const { result } = setupHook(() => useOptions({ source, options }), fromJS({}));

      expect(result.current).toStrictEqual(options);
    });
  });
});
