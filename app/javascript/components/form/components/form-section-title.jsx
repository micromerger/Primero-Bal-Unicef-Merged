// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";

import { useI18n } from "../../i18n";

function FormSectionTitle({ formSection }) {
  const i18n = useI18n();
  const { name, expandable } = formSection;
  const title = i18n.getI18nStringFromObject(name);

  if (!title) {
    return null;
  }

  return expandable ? title : <h1>{title}</h1>;
}

FormSectionTitle.displayName = "FormSectionTitle";

FormSectionTitle.propTypes = {
  formSection: PropTypes.object
};

export default FormSectionTitle;
