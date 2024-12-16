// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import { Drawer, List, useMediaQuery, Divider, IconButton, Box } from "@mui/material";
import { useCallback, useEffect, useState } from "react";
import { useDispatch } from "react-redux";
import CloseIcon from "@mui/icons-material/Close";
import { push } from "connected-react-router";
import { isEqual } from "lodash";
import { cx } from "@emotion/css";

import { ROUTES, PERMITTED_URL, APPLICATION_NAV } from "../../config";
import AgencyLogo from "../agency-logo";
import ModuleLogo from "../module-logo";
import BalLogo from "../../images/kpk_logo.png";
import useMemoizedSelector from "../../libs/use-memoized-selector";
import MobileToolbar from "../mobile-toolbar";
import { useApp } from "../application";
import Permission, { usePermissions, MANAGE, RESOURCES } from "../permissions";
import { getLocationsAvailable } from "../application/selectors";
import TranslationsToggle from "../translations-toggle";
import NetworkIndicator from "../network-indicator";
import { getPermissions } from "../user";
import ActionDialog, { useDialog } from "../action-dialog";
import { useI18n } from "../i18n";
import { hasQueueData } from "../connectivity/selectors";
import FieldMode from "../network-indicator/components/field-mode";
import PoweredBy from "../powered-by";

import { NAME, LOGOUT_DIALOG } from "./constants";
import css from "./styles.css";
import { fetchAlerts } from "./action-creators";
import { getUserId, selectUsername, selectAlerts } from "./selectors";
import MenuEntry from "./components/menu-entry";

function Nav() {
  const mobileDisplay = useMediaQuery(theme => theme.breakpoints.down("sm"));
  const dispatch = useDispatch();
  const i18n = useI18n();
  const [drawerOpen, setDrawerOpen] = useState(false);

  const { dialogOpen, dialogClose } = useDialog(LOGOUT_DIALOG);

  useEffect(() => {
    dispatch(fetchAlerts());
  }, []);

  const { demo, useContainedNavStyle } = useApp();
  const username = useMemoizedSelector(state => selectUsername(state), isEqual);
  const userId = useMemoizedSelector(state => getUserId(state), isEqual);
  const dataAlerts = useMemoizedSelector(state => selectAlerts(state), isEqual);
  const permissions = useMemoizedSelector(state => getPermissions(state), isEqual);
  const hasLocationsAvailable = useMemoizedSelector(state => getLocationsAvailable(state), isEqual);
  const hasUnsubmittedOfflineChanges = useMemoizedSelector(state => hasQueueData(state));

  const canManageMetadata = usePermissions(RESOURCES.metadata, MANAGE);

  const handleToggleDrawer = open => event => {
    if (event.type === "keydown" && (event.key === "Tab" || event.key === "Shift")) {
      return;
    }

    setDrawerOpen(open);
  };

  const handleLogoutCancel = () => dialogClose();

  const handleLogout = useCallback(() => {
    dispatch(push(ROUTES.logout));
  }, []);

  const permittedMenuEntries = menuEntries => {
    return menuEntries.map(menuEntry => {
      const key = menuEntry.to || menuEntry.component;

      if (menuEntry.component) {
        const CustomComponent = {
          fieldMode: FieldMode
        }[menuEntry.component];

        return <CustomComponent key={key} />;
      }

      const jewel = dataAlerts.get(menuEntry?.jewelCount, null);
      const route = `/${menuEntry.to.split("/").filter(Boolean)[0]}`;
      const jewelCount =
        jewel ||
        (canManageMetadata && route === ROUTES.admin && !hasLocationsAvailable) ||
        (hasUnsubmittedOfflineChanges && route === ROUTES.support);
      const renderedMenuEntries = (
        <MenuEntry
          key={key}
          menuEntry={menuEntry}
          mobileDisplay={mobileDisplay}
          jewelCount={jewelCount}
          username={username}
          closeDrawer={handleToggleDrawer(false)}
        />
      );

      return PERMITTED_URL.includes(route) ? (
        renderedMenuEntries
      ) : (
        <Permission key={key} resources={menuEntry.resources} actions={menuEntry.actions}>
          {renderedMenuEntries}
        </Permission>
      );
    });
  };

  const navListClasses = cx(css.navList, { [css.contained]: useContainedNavStyle });
  const translationsToggleClass = cx(css.translationToggle, css.navTranslationsToggle, {
    [css.contained]: useContainedNavStyle
  });
  const drawerHeaderClasses = cx(css.drawerHeader, { [css.drawerHeaderContained]: useContainedNavStyle });

  const drawerContent = (
    <>
        {/* <ModuleLogo username={username} /> */}
        <div className={css.box}>
        <img src={BalLogo} height="100%" width="80%"  alt="Logo" />
 {/* <p className={css.head}>CP-IMS</p>   */}
       </div>
      <div className={css.drawerHeaderContainer}>
        <Box sx={{ display: { md: "none", xs: "block" } }}>
          <div className={drawerHeaderClasses}>
            <IconButton size="large" onClick={handleToggleDrawer(false)}>
              <CloseIcon />
            </IconButton>
          </div>
          <Divider />
        </Box>
      </div>
      <div className={css.navNetworkIndicator}>
        <NetworkIndicator />
      </div>
      <List className={navListClasses}>{permittedMenuEntries(APPLICATION_NAV(permissions, userId))}</List>
      <div className={css.navAgencies}>
        <AgencyLogo />
      </div>
      <div className={translationsToggleClass}>
        <TranslationsToggle />
      </div>
      <PoweredBy />
    </>
  );

  const commonDrawerProps = {
    anchor: "left",
    open: drawerOpen,
    classes: {
      root: css.drawerRoot,
      paper: css[demo ? "drawerPaper-demo" : "drawerPaper"]
    },
    onClose: handleToggleDrawer(false)
  };

  return (
    <nav className={css.nav}>
      <MobileToolbar
        openDrawer={handleToggleDrawer(true)}
        hasUnsubmittedOfflineChanges={hasUnsubmittedOfflineChanges}
      />
      <Box sx={{ display: { md: "none", xs: "block" } }}>
        <Drawer
          variant="temporary"
          {...commonDrawerProps}
          ModalProps={{
            keepMounted: true
          }}
        >
          {drawerContent}
        </Drawer>
      </Box>
      <Box sx={{ display: { xs: "none", md: "block" } }}>
        <Drawer variant="permanent" {...commonDrawerProps}>
          {drawerContent}
        </Drawer>
      </Box>
      <ActionDialog
        dialogTitle={i18n.t("messages.logout_dialog_header")}
        cancelHandler={handleLogoutCancel}
        successHandler={handleLogout}
        confirmButtonLabel={i18n.t("buttons.logout")}
        onClose={dialogClose}
        open={dialogOpen}
      >
        {i18n.t("messages.logout_offline_warning")}
      </ActionDialog>
    </nav>
  );
}

Nav.displayName = NAME;

export default Nav;
