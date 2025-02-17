// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import isEmpty from "lodash/isEmpty";
import every from "lodash/every";

import { CONSENT_GIVEN_FIELD_BY_MODULE, MODULE_TYPE_FIELD } from "../../../../config";
import buildAppliedFilters from "../../utils/build-applied-filters";

export const getInternalFields = (values, fields) => {
  return Object.entries(values).reduce((obj, item) => {
    const o = obj;
    const [key, value] = item;

    if (fields.includes(key) && !isEmpty(value)) {
      o[key] = value;
    }

    return o;
  }, {});
};

export const internalFieldsDirty = (values, fields) => {
  const data = getInternalFields(values, fields);

  return Object.keys(data).length > 0;
};

export const hasProvidedConsent = record =>
  every(CONSENT_GIVEN_FIELD_BY_MODULE[record.get(MODULE_TYPE_FIELD)], field => record.get(field));

export const generatePath = (constant, recordId, recordsIds) => {
  const [recordType, transitionType] = constant.split("/");

  if (!isEmpty(recordsIds)) {
    return constant;
  }

  return [recordType, recordId, transitionType].join("/");
};

export const getUserFilters = filters =>
  Object.entries(filters).reduce((acc, entry) => {
    return entry[1] ? { ...acc, [entry[0]]: entry[1] } : acc;
  }, {});

export const searchableValue = (field, options, disableControl) => {
  const { value } = field;
  const selected = options.filter(option => option.value === value)[0];

  return !disableControl && value !== "" ? selected : null;
};

export const buildDataAssign = ({
  values,
  selectedIds,
  record,
  selectedRecordsLength,
  currentRecordsSize,
  totalRecords,
  appliedFilters,
  queryParams
}) => {
  if (isEmpty(selectedIds)) {
    return values;
  }

  const allCurrentRowsSelected =
    selectedRecordsLength > 0 && currentRecordsSize > 0 && selectedRecordsLength === currentRecordsSize;
  const allRecordsSelected = selectedRecordsLength === totalRecords;

  const filters = buildAppliedFilters(
    Boolean(record),
    allCurrentRowsSelected,
    selectedIds,
    appliedFilters,
    queryParams,
    record,
    allRecordsSelected
  );

  return { ...values, ...filters, totalRecords };
};
