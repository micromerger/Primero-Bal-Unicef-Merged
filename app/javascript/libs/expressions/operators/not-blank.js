import { List } from "immutable";
import isNil from "lodash/isNil";
import isString from "lodash/isString";

import { COMPARISON_OPERATORS } from "../constants";
import getDataValue from "../utils/get-data-value";

const isBlank = value => {
  if (isNil(value)) {
    return true;
  }

  if (isString(value)) {
    return value.trim() === "";
  }

  if (Array.isArray(value)) {
    return value.length === 0;
  }

  if (List.isList(value)) {
    return value.isEmpty();
  }

  return false;
};

export default expression => ({
  expression,
  operator: COMPARISON_OPERATORS.NOT_BLANK,
  evaluate: data => [expression].flat().every(field => !isBlank(getDataValue(field, data)))
});
