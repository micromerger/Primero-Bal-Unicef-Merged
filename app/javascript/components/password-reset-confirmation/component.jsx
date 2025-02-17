// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";

import ActionDialog from "../action-dialog";
import { useI18n } from "../i18n";
import { getPasswordResetLoading } from "../pages/admin/users-form/selectors";
import useMemoizedSelector from "../../libs/use-memoized-selector";

import { NAME } from "./constants";

function Component({ open = false, handleCancel, handleSuccess }) {
  const i18n = useI18n();

  const pending = useMemoizedSelector(state => getPasswordResetLoading(state));

  const successButtonProps = {
    color: "primary",
    variant: "contained",
    autoFocus: true
  };

  return (
    <ActionDialog
      open={open}
      successHandler={handleSuccess}
      cancelHandler={handleCancel}
      dialogTitle={i18n.t("user.password_reset_header")}
      pending={pending}
      omitCloseAfterSuccess
      confirmButtonLabel={i18n.t("buttons.ok")}
      confirmButtonProps={successButtonProps}
      onClose={handleCancel}
    >
      <p>{i18n.t("user.password_reset_text")}</p>
    </ActionDialog>
  );
}

Component.displayName = NAME;

Component.propTypes = {
  handleCancel: PropTypes.func,
  handleSuccess: PropTypes.func,
  open: PropTypes.bool
};

export default Component;
