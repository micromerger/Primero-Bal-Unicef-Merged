// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import { useDispatch } from "react-redux";
import PropTypes from "prop-types";

import PageHeading from "../../../page/components/page-heading";
import { useI18n } from "../../../i18n";
import { useMemoizedSelector } from "../../../../libs";

import { getIdentityProviders } from "./selectors";
import { NAME } from "./config";
import css from "./styles.css";
import PrimeroIdpLink from "./components/primero-idp-link";
import PrimeroIdpSelect from "./components/primero-idp-select";

function Container({ showTitle = true }) {
  const i18n = useI18n();

  const dispatch = useDispatch();

  const identityProviders = useMemoizedSelector(state => getIdentityProviders(state));

  return (
    <>
      {showTitle && <PageHeading title={i18n.t("login.title")} noPadding noElevation />}
      <PrimeroIdpSelect identityProviders={identityProviders} css={css} />
      <PrimeroIdpLink identityProviders={identityProviders} i18n={i18n} dispatch={dispatch} css={css} />
    </>
  );
}

Container.displayName = NAME;

Container.propTypes = {
  showTitle: PropTypes.bool
};

export default Container;
