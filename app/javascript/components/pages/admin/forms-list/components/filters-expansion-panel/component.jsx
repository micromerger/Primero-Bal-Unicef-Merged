// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";
import { Accordion, AccordionSummary, AccordionDetails } from "@mui/material";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";

import FilterInput from "../filter-input";

function Component({ name, handleSetFilterValue, options = [], id, filterValues = {} }) {
  return (
    <Accordion elevation={3} defaultExpanded data-testid="accordion">
      <AccordionSummary expandIcon={<ExpandMoreIcon />}>{name}</AccordionSummary>
      <AccordionDetails>
        <FilterInput
          handleSetFilterValue={handleSetFilterValue}
          name={name}
          options={options}
          id={id}
          filterValues={filterValues}
        />
      </AccordionDetails>
    </Accordion>
  );
}

Component.displayName = "FiltersExpansionPanel";

Component.propTypes = {
  filterValues: PropTypes.object,
  handleSetFilterValue: PropTypes.func.isRequired,
  id: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  options: PropTypes.array
};

export default Component;
