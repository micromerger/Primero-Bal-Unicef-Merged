// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import { ORIENTATION } from "./constants";

/* eslint-disable import/prefer-default-export */
export const getLocaleDir = locale => {
  switch (locale) {
    case "ar":
    case "ar-LB":
    case "ku":
    case "ku-IQ":
    case "zh":
    case "ar-SD":
    case "ar-JO":
    case "ar-IQ":
    case "fa-AF":
    case "ps-AF":
    case "aeb":
    case "ar-SY":
      return ORIENTATION.rtl;
    default:
      return ORIENTATION.ltr;
  }
};
