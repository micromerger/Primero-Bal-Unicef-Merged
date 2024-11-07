// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";
import { Icon } from "@mui/material";
import DragIndicatorIcon from "@mui/icons-material/DragIndicator";

import css from "../../styles.css";

function Component({ isDragDisabled = false, ...props }) {
  const classes = isDragDisabled ? { classes: { root: css.dragIndicator } } : {};

  return (
    <Icon {...props} {...classes} data-testid="drag-indicator">
      <DragIndicatorIcon />
    </Icon>
  );
}

Component.displayName = "DragIndicator";

Component.propTypes = {
  isDragDisabled: PropTypes.bool,
  props: PropTypes.object
};

export default Component;
