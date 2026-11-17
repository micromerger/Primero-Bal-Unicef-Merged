import first from "lodash/first";
import isObject from "lodash/isObject";
import isString from "lodash/isString";
import uniq from "lodash/uniq";

import { COMPARISON_OPERATORS } from "../constants";
import toExpression from "../to-expression";

import isExpression from "./is-expression";
import isLogicalOperator from "./is-logical-operator";
import isMathematicalOperator from "./is-mathematical-operator";

const collectFields = expression => {
  const [operator, value] = first(Object.entries(isExpression(expression) ? expression : toExpression(expression)));

  if (isLogicalOperator(operator)) {
    return [value].flat().flatMap(nested => collectFields(nested));
  }

  if (isMathematicalOperator(operator)) {
    return [value?.data ?? value]
      .flat()
      .flatMap(entry => (isObject(entry) ? collectFields(entry) : entry))
      .filter(isString);
  }

  if (operator === COMPARISON_OPERATORS.NOT_BLANK) {
    return [value].flat();
  }

  return Object.keys(value);
};

export default expression => uniq(collectFields(expression));
