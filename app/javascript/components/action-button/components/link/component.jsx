// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";
import { Link } from "@mui/material";

import { NAME } from "./constants";

function Component({ text, id, ...options }) {
  const { rest, ...remainder } = options;

  if (rest.disabled) {
    return <div className={options.className}>{text}</div>;
  }

  return (
    <Link id={id} underline="hover" {...rest} {...remainder}>
      {text}
    </Link>
  );
}

Component.displayName = NAME;

Component.propTypes = {
  id: PropTypes.string.isRequired,
  text: PropTypes.string
};

export default Component;
