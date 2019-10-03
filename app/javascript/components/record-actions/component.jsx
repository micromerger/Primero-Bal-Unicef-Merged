import React, { useState } from "react";
import PropTypes from "prop-types";
import { IconButton, Menu, MenuItem } from "@material-ui/core";
import MoreVertIcon from "@material-ui/icons/MoreVert";
import { useI18n } from "components/i18n";
import { Transitions } from "./transitions";
import { ToggleOpen } from "./toggle-open";
import { ToggleEnable } from "./toggle-enable";

const RecordActions = ({ recordType, iconColor, record, mode }) => {
  const i18n = useI18n();
  const [anchorEl, setAnchorEl] = useState(null);
  const [openReopenDialog, setOpenReopenDialog] = useState(false);
  const [transitionType, setTransitionType] = useState("");
  const [openEnableDialog, setOpenEnableDialog] = useState(false);

  const enableState =
    record && record.get("record_state") ? "disable" : "enable";

  const openState =
    record && record.get("status") === "open" ? "close" : "reopen";

  const handleClick = event => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleItemAction = itemAction => {
    handleClose();
    itemAction();
  };

  const handleReopenDialogOpen = () => {
    setOpenReopenDialog(true);
  };

  const handleReopenDialogClose = () => {
    setOpenReopenDialog(false);
  };

  const handleEnableDialogOpen = () => {
    setOpenEnableDialog(true);
  };

  const handleEnableDialogClose = () => {
    setOpenEnableDialog(false);
  };

  const actions = [
    {
      name: i18n.t("buttons.import"),
      action: () => console.log("Some action"),
      recordType: "all"
    },
    {
      name: i18n.t("exports.custom_exports.label"),
      action: () => console.log("Some action"),
      recordType: "all"
    },
    {
      name: i18n.t("buttons.mark_for_mobile"),
      action: () => console.log("Some action"),
      recordType: "all"
    },
    {
      name: i18n.t("buttons.unmark_for_mobile"),
      action: () => console.log("Some action"),
      recordType: "all"
    },
    {
      name: `${i18n.t("buttons.referral")} ${recordType}`,
      action: () => setTransitionType("referral"),
      recordType: "cases"
    },
    {
      name: `${i18n.t("buttons.reassign")} ${recordType}`,
      action: () => setTransitionType("reassign"),
      recordType: "cases"
    },
    {
      name: `${i18n.t("buttons.transfer")} ${recordType}`,
      action: () => setTransitionType("transfer"),
      recordType: "cases"
    },
    {
      name: i18n.t("actions.incident_details_from_case"),
      action: () => console.log("Some action"),
      recordType: "cases"
    },
    {
      name: i18n.t("actions.services_section_from_case"),
      action: () => console.log("Some action"),
      recordType: "cases"
    },
    {
      name: i18n.t(`actions.${openState}`),
      action: handleReopenDialogOpen,
      recordType: "all",
      condition: mode && mode.isShow
    },
    {
      name: i18n.t(`actions.${enableState}`),
      action: handleEnableDialogOpen,
      recordType: "all",
      condition: mode && mode.isShow
    }
  ];

  return (
    <>
      {mode && mode.isShow ? (
        <IconButton
          aria-label="more"
          aria-controls="long-menu"
          aria-haspopup="true"
          onClick={handleClick}
        >
          <MoreVertIcon color={iconColor} />
        </IconButton>
      ) : null}

      <Menu
        id="long-menu"
        anchorEl={anchorEl}
        keepMounted
        open={Boolean(anchorEl)}
        onClose={handleClose}
      >
        {actions
          .filter(a => {
            return (
              (a.recordType === "all" ||
                a.recordType === recordType ||
                (Array.isArray(a.recordType) &&
                  a.recordType.includes(recordType))) &&
              (typeof a.condition === "undefined" || a.condition)
            );
          })
          .map(action => (
            <MenuItem
              key={action.name}
              selected={action.name === "Pyxis"}
              onClick={() => handleItemAction(action.action)}
            >
              {action.name}
            </MenuItem>
          ))}
      </Menu>

      <ToggleOpen
        close={handleReopenDialogClose}
        openReopenDialog={openReopenDialog}
        record={record}
        recordType={recordType}
      />
      <Transitions
        transitionType={transitionType}
        record={record}
        setTransitionType={setTransitionType}
      />
      <ToggleEnable
        close={handleEnableDialogClose}
        openEnableDialog={openEnableDialog}
        record={record}
        recordType={recordType}
      />
    </>
  );
};

RecordActions.propTypes = {
  recordType: PropTypes.string.isRequired,
  iconColor: PropTypes.string,
  record: PropTypes.object,
  mode: PropTypes.object
};

export default RecordActions;
