// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";

import { PROVIDED_CONSENT_NAME as NAME } from "./constants";
import ProvidedForm from "./provided-form";

function ProvidedConsent({ canConsentOverride, providedConsent, setDisabled, recordType }) {
  if (providedConsent) {
    return null;
  }
  const providedConsentFormProps = {
    canConsentOverride,
    setDisabled,
    recordType
  };

  return <ProvidedForm {...providedConsentFormProps} />;
}

ProvidedConsent.displayName = NAME;

ProvidedConsent.propTypes = {
  canConsentOverride: PropTypes.bool,
  providedConsent: PropTypes.bool,
  recordType: PropTypes.string,
  setDisabled: PropTypes.func
};

export default ProvidedConsent;
