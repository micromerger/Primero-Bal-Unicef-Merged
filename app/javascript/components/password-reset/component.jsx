// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import qs from "qs";
import { useLocation } from "react-router-dom";
import { useDispatch } from "react-redux";
import CheckIcon from "@mui/icons-material/Check";

import { PageHeading } from "../page";
import Form, { FormAction } from "../form";
import { useI18n } from "../i18n";
import { getSavingPassword, resetPassword } from "../user";
import useMemoizedSelector from "../../libs/use-memoized-selector";

import { form, validationSchema } from "./form";
import { NAME, RESET_PASSWORD_FORM } from "./constants";

function Component() {
  const i18n = useI18n();
  const location = useLocation();
  const dispatch = useDispatch();
  const queryParams = qs.parse(location.search.replace("?", ""));

  // eslint-disable-next-line camelcase
  const { reset_password_token } = queryParams;

  const saving = useMemoizedSelector(state => getSavingPassword(state));

  const handleSubmit = values => {
    // eslint-disable-next-line camelcase
    dispatch(resetPassword({ user: { ...values.user, reset_password_token } }));
  };

  return (
    <div>
      <PageHeading title="Set Password" />
      <Form
        formSections={form(i18n)}
        validations={validationSchema(i18n)}
        onSubmit={handleSubmit}
        formID={RESET_PASSWORD_FORM}
      />
      <FormAction
        text={i18n.t("buttons.save")}
        startIcon={<CheckIcon />}
        savingRecord={saving}
        options={{ form: RESET_PASSWORD_FORM, type: "submit" }}
      />
    </div>
  );
}

Component.displayName = NAME;

export default Component;
