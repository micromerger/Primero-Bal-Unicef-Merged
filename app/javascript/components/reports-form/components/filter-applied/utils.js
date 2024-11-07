// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

/* eslint-disable camelcase, import/prefer-default-export */

import { NOT_NULL } from "../../constants";
import { DATE_FIELD } from "../../../form";

export const getConstraintLabel = (data, field, constraints, i18n) => {
  const { constraint, value } = data;

  if (
    (typeof constraint === "boolean" && constraint) ||
    (Array.isArray(value) && value.includes(NOT_NULL)) ||
    constraint === NOT_NULL ||
    constraint === "true"
  ) {
    return i18n.t(constraints.default.not_null);
  }

  if (field?.type === DATE_FIELD && Object.keys(constraints.date).includes(constraint)) {
    return i18n.t(constraints.date[constraint]);
  }

  return Array.isArray(value) ? "" : i18n.t(constraints.default[constraint]);
};

export const getFieldNameForAttribute = attribute =>
  attribute?.startsWith("loc:") ? attribute.replace("loc:", "").replace(/[0-5]/, "") : attribute;
