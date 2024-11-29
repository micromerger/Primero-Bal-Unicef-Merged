// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";
import clsx from "clsx";
import { useMediaQuery } from "@material-ui/core";

import ModuleLogo from "../../../module-logo";
import AgencyLogo from "../../../agency-logo";
import SindhLogo from "../../../../images/mohr_logo.jpg";
import primeroLogo from "../../../../images/primero-logo.png";
import Notifier from "../../../notifier";
import DemoIndicator from "../../../demo-indicator";
import { useMemoizedSelector } from "../../../../libs";
import { useApp } from "../../../application";
import { hasAgencyLogos } from "../../../application/selectors";
import LoginLayoutFooter from "../login-layout-footer";

import { NAME } from "./constants";
import css from "./styles.css";

const Component = ({ children }) => {
  const mobileDisplay = useMediaQuery(theme => theme.breakpoints.down("sm"));
  const { demo, hasLoginLogo, useContainedNavStyle } = useApp();
  const hasLogos = useMemoizedSelector(state => hasAgencyLogos(state));

  const classes = clsx(css.primeroBackground, {
    [css.primeroBackgroundImage]: hasLoginLogo,
    [css.primeroBackgroundImageDemo]: hasLoginLogo && demo,
    [css.demoBackground]: demo
  });
  const classesLoginLogo = clsx(css.loginLogo, { [css.hideLoginLogo]: !hasLogos });
  const classesAuthDiv = clsx(css.auth, { [css.noLogosWidth]: !hasLogos });
  const isContainedAndMobile = useContainedNavStyle && mobileDisplay;

  return (
    <>
      <DemoIndicator isDemo={demo} />
      <Notifier />
      <div className={classes}>
        <div className={css.content}>
                    {/* <div className={css.loginHeader}>
            <ModuleLogo white />
          </div> */}
          <div className={css.box}>

<img src={SindhLogo} height="250px" width="240px" alt="Logo" />
<h2 className={css.head}>Government of Sindh</h2>
{/* <h3 className={css.head}>s</h3> */}
</div>
          <div className={css.authContainer}>
            <div className={classesAuthDiv}>
              <div className={css.formContainer}>
                <div className={css.form}>{children}</div>
              </div>
              <div className={css.loginLogo}>
                <img src={primeroLogo} width="240px" alt="Logo" />
                {/* <AgencyLogo alwaysFullLogo /> */}
              </div>
            </div>
            {isContainedAndMobile && <LoginLayoutFooter useContainedNavStyle />}
          </div>
        </div>
        {isContainedAndMobile || <LoginLayoutFooter />}
      </div>
    </>
  );
};

Component.displayName = NAME;

Component.propTypes = {
  children: PropTypes.node
};

export default Component;
