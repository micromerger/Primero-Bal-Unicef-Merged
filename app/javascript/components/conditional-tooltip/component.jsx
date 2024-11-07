// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import { Tooltip } from "@mui/material";
import PropTypes from "prop-types";

function Component({ children, condition, title }) {
  if (condition) {
    return (
      <Tooltip title={title} enterTouchDelay={20}>
        <div>{children}</div>
      </Tooltip>
    );
  }

  return children;
}

Component.displayName = "ConditionalTooltip";

Component.propTypes = {
  children: PropTypes.node.isRequired,
  condition: PropTypes.bool.isRequired,
  title: PropTypes.string.isRequired
};

export default Component;
