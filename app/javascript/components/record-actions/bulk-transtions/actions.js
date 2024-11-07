// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import { namespaceActions } from "../../../libs";

import NAMESPACE from "./namespace";

const actions = namespaceActions(NAMESPACE, [
  "BULK_ASSIGN_USER_SAVE",
  "BULK_ASSIGN_USER_SAVE_SUCCESS",
  "BULK_ASSIGN_USER_SAVE_STARTED",
  "BULK_ASSIGN_USER_SAVE_FAILURE",
  "BULK_ASSIGN_USER_SAVE_FINISHED",
  "BULK_ASSIGN_USER_SELECTED_RECORDS_LENGTH",
  "CLEAR_BULK_ASSIGN_MESSAGES"
]);

export default {
  ...actions,
  BULK_ASSIGN_CASES: "cases/assigns",
  BULK_ASSIGN_INCIDENTS: "incidents/assigns"
};
