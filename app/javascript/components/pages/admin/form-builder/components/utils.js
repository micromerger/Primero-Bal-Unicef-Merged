// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import get from "lodash/get";
import omit from "lodash/omit";
import { fromJS } from "immutable";

import { getObjectPath } from "../../../../../libs";
import { LOCALE_KEYS } from "../../../../../config";

import { MULTI_SELECT_FIELD, DATE_TIME_FIELD } from "./custom-field-selector-dialog/constants";

export const getFieldsAttribute = isNested => (isNested ? "subform_section.fields" : "fields");

export const getFiedListItemTheme = currentTheme => ({
  ...currentTheme,
  overrides: {
    ...currentTheme.overrides,
    MuiFormControl: {
      ...currentTheme.overrides.MuiFormControl,
      root: {
        ...currentTheme.overrides.MuiFormControl.root,
        marginBottom: 0
      }
    },
    MuiCheckbox: {
      ...currentTheme.overrides.MuiCheckbox,
      root: {
        ...currentTheme.overrides.MuiCheckbox.root,
        padding: "0 0.2em",
        margin: "0 0.4em"
      }
    },
    MuiFormControlLabel: {
      root: {
        ...currentTheme.overrides.MuiFormControlLabel.root,
        marginLeft: 0,
        marginRight: 0
      }
    },
    MuiButton: {
      root: {
        "&.Mui-disabled": {
          color: "rgba(0, 0, 0, 0.26)",
          backgroundColor: "transparent !important"
        }
      }
    }
  }
});

export const getLabelTypeField = field => {
  const isMultiSelect = field.get("multi_select");
  const isDateTime = field.get("date_include_time");

  if (isMultiSelect) {
    return MULTI_SELECT_FIELD;
  }
  if (isDateTime) {
    return DATE_TIME_FIELD;
  }

  return field.get("type") === "date_range" ? "date_range_field" : field.get("type");
};

export const localesToRender = i18n => fromJS(i18n.applicationLocales.filter(locale => locale.id !== LOCALE_KEYS.en));

export const setFieldDataInFormContext = ({ name, data, fieldsPath, contextFields, register, setValue }) => {
  getObjectPath("", omit(data, ["display_name", "display_conditions_record"])).forEach(path => {
    const isDisabledProp = path.endsWith("disabled");
    const value = get(data, path);
    const fieldFullPath = `${fieldsPath || "fields"}.${name}.${path}`;

    if (!contextFields[fieldFullPath]) {
      register({ name: fieldFullPath });
    }

    setValue(fieldFullPath, isDisabledProp ? !value : value, { shouldDirty: true });
  });

  const fieldFullPath = `${fieldsPath || "fields"}.${name}.display_conditions_record`;

  setValue(fieldFullPath, data.display_conditions_record, { shouldDirty: true });
};
