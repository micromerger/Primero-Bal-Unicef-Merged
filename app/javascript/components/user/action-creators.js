import { DB_COLLECTIONS_NAMES } from "../../db";
import { loadApplicationResources } from "../application";
import { SET_USER_LOCALE } from "../i18n";
import { SET_DIALOG } from "../action-dialog";
import { LOGIN_DIALOG } from "../login-dialog";
import { QUEUE_READY } from "../../libs/queue";
import connectivityActions from "../connectivity/actions";

import actions from "./actions";

const queueReady = {
  action: connectivityActions.QUEUE_STATUS,
  payload: QUEUE_READY
};

export const setUser = payload => {
  return {
    type: actions.SET_AUTHENTICATED_USER,
    payload
  };
};

export const fetchAuthenticatedUserData = id => ({
  type: actions.FETCH_USER_DATA,
  api: {
    path: `users/${id}`,
    params: {
      extended: true
    },
    db: {
      collection: DB_COLLECTIONS_NAMES.USER
    },
    successCallback: [SET_USER_LOCALE]
  }
});

export const setAuthenticatedUser = user => async dispatch => {
  dispatch(setUser(user));
  dispatch(fetchAuthenticatedUserData(user.id));
  dispatch(loadApplicationResources());
};

export const attemptSignout = () => ({
  type: actions.LOGOUT,
  api: {
    path: "tokens",
    method: "DELETE",
    successCallback: actions.LOGOUT_SUCCESS_CALLBACK
  }
});

export const checkUserAuthentication = () => async dispatch => {
  const user = JSON.parse(localStorage.getItem("user"));

  if (user) {
    dispatch(setAuthenticatedUser(user));
  }
};

export const refreshToken = checkUserAuth => ({
  type: actions.REFRESH_USER_TOKEN,
  api: {
    path: "tokens",
    method: "POST",
    ...(checkUserAuth && {
      successCallback: [queueReady],
      failureCallback: [
        {
          action: connectivityActions.PENDING_USER_LOGIN,
          payload: true
        },
        {
          action: SET_DIALOG,
          payload: { dialog: LOGIN_DIALOG, open: true, pending: false },
          dispatchIfStatus: 401
        }
      ]
    })
  }
});