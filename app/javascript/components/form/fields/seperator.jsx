// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";
import { Typography } from "@mui/material";

import css from "./styles.css";

function Seperator({ commonInputProps }) {
  const { label, id = "" } = commonInputProps;

  if (!label) {
    return <div id={id} className={css.separator} />;
  }

  return (
    <Typography id={id} variant="h6">
      {label}
    </Typography>
  );
}

Seperator.displayName = "Seperator";

Seperator.propTypes = {
  commonInputProps: PropTypes.shape({
    id: PropTypes.string,
    label: PropTypes.string
  })
};

export default Seperator;
