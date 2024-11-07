// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import first from "lodash/first";
import isObject from "lodash/isObject";

import isMathematicalOperator from "./utils/is-mathematical-operator";
import { buildOperator, isLogicalOperator, isExpression } from "./utils";
import toExpression from "./to-expression";

const parseExpression = expression => {
  const [operator, value] = first(Object.entries(isExpression(expression) ? expression : toExpression(expression)));

  if (isLogicalOperator(operator)) {
    const expressions = Array.isArray(value) ? value.map(nested => parseExpression(nested)) : parseExpression(value);

    return buildOperator(operator, expressions);
  }

  if (isMathematicalOperator(operator)) {
    const data = value?.data ?? value;
    const extra = value?.extra;
    const mathExp = Array.isArray(data)
      ? data.map(nested => (isObject(nested) ? parseExpression(nested) : nested))
      : parseExpression(data);

    return buildOperator(operator, mathExp, extra);
  }

  return buildOperator(operator, value);
};

export default parseExpression;
