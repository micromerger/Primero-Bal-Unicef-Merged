// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";
import { Fragment, memo } from "react";
import { cx } from "@emotion/css";

import { getAgencyLogos } from "../application/selectors";
import useMemoizedSelector from "../../libs/use-memoized-selector";

import css from "./styles.css";

function AgencyLogo({ alwaysFullLogo = false }) {
  const agencyLogos = useMemoizedSelector(state => getAgencyLogos(state));

  const renderLogos = () => {
    return agencyLogos.map(agency => {
      const uniqueId = agency.get("unique_id");
      const styleIcon = { backgroundImage: `url(${agency.get("logo_icon")})` };
      const styleFull = { backgroundImage: `url(${agency.get("logo_full")})` };
      const classesIcon = cx([css.agencyLogo, css.agencyLogoIcon]);
      const classesFull = cx(css.agencyLogo, { [css.agencyLogoFull]: !alwaysFullLogo });

      const fullLogo = (
        <div id={`${uniqueId}-logo`} key={`${uniqueId}-logo`} className={classesFull} style={styleFull} />
      );

      if (alwaysFullLogo) {
        return fullLogo;
      }

      return (
        <Fragment key={`${uniqueId}-logo`}>
          <div id={`${uniqueId}-logo`} className={classesIcon} style={styleIcon} data-testid="background" />
          {fullLogo}
        </Fragment>
      );
    });
  };

  return <div className={css.agencyLogoContainer}>{renderLogos()}</div>;
}

AgencyLogo.displayName = "AgencyLogo";

AgencyLogo.propTypes = {
  alwaysFullLogo: PropTypes.bool
};

export default memo(AgencyLogo);
