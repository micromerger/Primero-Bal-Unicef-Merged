// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";
import { Paper } from "@mui/material";
import { cx } from "@emotion/css";

import css from "./styles.css";
import { NAME } from "./constants";

function TabPanel({ tab, index, children }) {
  const className = cx(css.hideTab, css.tabContainer, {
    [css.showTab]: tab === index
  });

  return (
    <Paper elevation={0} className={className} data-testid="tab-panel">
      {children}
    </Paper>
  );
}

TabPanel.displayName = NAME;

TabPanel.propTypes = {
  children: PropTypes.node,
  index: PropTypes.number,
  tab: PropTypes.number
};

export default TabPanel;
