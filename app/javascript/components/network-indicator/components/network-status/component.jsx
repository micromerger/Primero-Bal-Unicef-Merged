// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";
import SignalWifiOffIcon from "@mui/icons-material/SignalWifiOff";
import SignalWifi4BarIcon from "@mui/icons-material/SignalWifi4Bar";
import { cx } from "@emotion/css";
import { ListItem, ListItemIcon, ListItemText } from "@mui/material";

import { useI18n } from "../../../i18n";
import { useApp } from "../../../application";
import { getConnectionStatus } from "../../../connectivity/utils";
import { CONNECTED, CONNECTION_LOST, FIELD_MODE_OFFLINE } from "../../../connectivity/constants";

import css from "./styles.css";

function Component({ mobile, contained }) {
  const i18n = useI18n();
  const { online, fieldMode, useContainedNavStyle } = useApp();

  const mode = {
    [FIELD_MODE_OFFLINE]: {
      text: "offline",
      textStatus: "field_mode_offline",
      icon: SignalWifiOffIcon,
      color: "fieldMode"
    },
    [CONNECTED]: {
      text: "online",
      textStatus: "connected",
      icon: SignalWifi4BarIcon,
      color: "online"
    },
    [CONNECTION_LOST]: {
      text: "offline",
      textStatus: "no_connection",
      icon: SignalWifiOffIcon,
      color: "offline"
    }
  }[getConnectionStatus(online, fieldMode)];

  const offlineClasses = { [css.containedMobileOffline]: !online };

  const containerClasses = cx(css.container, css[mode.color], {
    [css.containedMobile]: useContainedNavStyle,
    ...offlineClasses
  });
  const listItemClasses = cx(css.navLink, css[mode.color], {
    [css.contained]: useContainedNavStyle,
    ...offlineClasses
  });

  if (mobile) {
    return (
      <div className={containerClasses}>
        <div className={css.icon}>
          <mode.icon color={mode.color} />
        </div>
        <div className={css.textContainer}>
          <div>{i18n.t(mode.text)}</div>
          {contained || <div>{i18n.t(mode.textStatus)}</div>}
        </div>
      </div>
    );
  }

  return (
    <ListItem classes={{ root: listItemClasses }}>
      <ListItemIcon className={css.listIcon}>
        <mode.icon />
      </ListItemIcon>
      <ListItemText
        classes={{ root: css.listTextRoot, primary: css.listText, secondary: css.listTextSecondary }}
        secondary={contained ? "" : i18n.t(mode.textStatus)}
      >
        {i18n.t(mode.text)}
      </ListItemText>
    </ListItem>
  );
}

Component.displayName = "NetworkStatus";

Component.propTypes = {
  contained: PropTypes.bool,
  mobile: PropTypes.bool
};

export default Component;
