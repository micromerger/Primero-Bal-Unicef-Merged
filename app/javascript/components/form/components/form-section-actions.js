// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";

import ActionButton from "../../action-button";

function FormSectionActions({ actions, css }) {
  if (!actions?.length) return null;

  return (
    <div className={css.formActions}>
      {actions.map((action, index) => (
        <ActionButton id={`form-section-action-button-${index}`} noTranslate key={action.text} {...action} />
      ))}
    </div>
  );
}

FormSectionActions.propTypes = {
  actions: PropTypes.array,
  css: PropTypes.object
};

FormSectionActions.displayName = "FormSectionActions";

export default FormSectionActions;
