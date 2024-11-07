// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";
import { useLocation, Link } from "react-router-dom";
import CreateIcon from "@mui/icons-material/Create";
import CheckIcon from "@mui/icons-material/Check";
import ClearIcon from "@mui/icons-material/Clear";

import { ACTION_BUTTONS_NAME } from "../constants";
import { useI18n } from "../../../../i18n";
import { getSavingRecord } from "../selectors";
import { FormAction } from "../../../../form";
import Permission, { RESOURCES, WRITE_RECORDS } from "../../../../permissions";
import ActionButton from "../../../../action-button";
import { ACTION_BUTTON_TYPES } from "../../../../action-button/constants";
import { useMemoizedSelector } from "../../../../../libs";

function Component({ formMode, formID, handleCancel, limitedProductionSite }) {
  const i18n = useI18n();
  const { pathname } = useLocation();

  const saving = useMemoizedSelector(state => getSavingRecord(state));

  const saveButton = (formMode.get("isEdit") || formMode.get("isNew")) && (
    <>
      <FormAction cancel actionHandler={handleCancel} text={i18n.t("buttons.cancel")} startIcon={<ClearIcon />} />
      <FormAction
        options={{ form: formID, type: "submit", hide: limitedProductionSite }}
        text={i18n.t("buttons.save")}
        savingRecord={saving}
        startIcon={<CheckIcon />}
      />
    </>
  );

  const editButton = formMode.get("isShow") && (
    <Permission resources={RESOURCES.roles} actions={WRITE_RECORDS}>
      <ActionButton
        icon={<CreateIcon />}
        text="buttons.edit"
        type={ACTION_BUTTON_TYPES.default}
        rest={{
          to: `${pathname}/edit`,
          component: Link,
          hide: limitedProductionSite
        }}
      />
    </Permission>
  );

  return (
    <>
      {editButton}
      {saveButton}
    </>
  );
}

Component.displayName = ACTION_BUTTONS_NAME;

Component.propTypes = {
  formID: PropTypes.string.isRequired,
  formMode: PropTypes.object.isRequired,
  handleCancel: PropTypes.func.isRequired,
  limitedProductionSite: PropTypes.bool
};

export default Component;
