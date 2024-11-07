// Copyright (c) 2014 - 2024 UNICEF. All rights reserved.

/* eslint-disable react/display-name */
import PropTypes from "prop-types";
import Autocomplete from "@mui/material/Autocomplete";
import { Chip } from "@mui/material";

import AutoCompleteInput from "./components/auto-complete-input";
import { NAME } from "./constants";
import css from "./styles.css";
import { optionLabel, optionEquality, optionDisabled, filterOptions } from "./utils";
import { listboxClasses, virtualize } from "./components/listbox-component";

function SearchableSelect({
  error,
  defaultValues = null,
  helperText = "",
  isClearable = true,
  isDisabled = false,
  isLoading = false,
  multiple = false,
  onChange,
  onBlur,
  onOpen,
  options = [],
  TextFieldProps = {},
  mode = {},
  InputLabelProps,
  optionIdKey = "value",
  optionLabelKey = "label",
  name,
  value: fieldValue
}) {
  const defaultEmptyValue = multiple ? [] : null;

  const initialValues = (() => {
    if (Array.isArray(defaultValues)) {
      const defaultValuesClear = defaultValues.filter(selected => selected[optionLabelKey]);
      const values = defaultValuesClear.map(selected => selected?.[optionIdKey] || null);

      return multiple ? values || [] : values[0] || null;
    }

    if (typeof defaultValues === "object") {
      return defaultValues?.[optionIdKey] || defaultEmptyValue;
    }

    return defaultValues || defaultEmptyValue;
  })();

  const renderTags = (value, getTagProps) =>
    value.map((option, index) => {
      const { onDelete, ...rest } = { ...getTagProps({ index }) };
      const chipProps = {
        ...(isDisabled || { onDelete }),
        ...rest,
        classes: {
          ...(mode.isShow && {
            disabled: css.disabledChip
          })
        }
      };

      return (
        <Chip
          data-testid="chip"
          size="small"
          label={optionLabel(option, options, optionIdKey, optionLabelKey)}
          {...chipProps}
          disabled={isDisabled}
        />
      );
    });

  const getSelectedOptions = (option, selected) => optionEquality(option, selected, optionIdKey);
  const getOptionLabel = option => optionLabel(option, options, optionIdKey, optionLabelKey);
  const handleOnChange = (_, value) => onChange(value);
  const handleRenderTags = (value, getTagProps) => renderTags(value, getTagProps);
  const currentOptionLabel = getOptionLabel(fieldValue || "", options, optionIdKey, optionLabelKey);

  return (
    <Autocomplete
      data-testid="autocomplete"
      id={name}
      onChange={handleOnChange}
      options={options}
      disabled={isDisabled}
      getOptionLabel={getOptionLabel}
      getOptionDisabled={optionDisabled}
      isOptionEqualToValue={getSelectedOptions}
      loading={isLoading}
      disableClearable={!isClearable}
      filterSelectedOptions
      filterOptions={filterOptions(currentOptionLabel)}
      value={initialValues}
      onOpen={onOpen && onOpen}
      multiple={multiple}
      onBlur={onBlur}
      ListboxComponent={virtualize(options.length)}
      classes={{ listbox: listboxClasses }}
      disableListWrap
      renderInput={params => (
        <AutoCompleteInput
          ref={params.InputProps.ref}
          mode={mode}
          data-testid="autocomplete-input"
          params={params}
          value={initialValues}
          helperText={helperText}
          InputLabelProps={InputLabelProps}
          TextFieldProps={TextFieldProps}
          isDisabled={isDisabled}
          isLoading={isLoading}
          multiple={multiple}
          currentOptionLabel={currentOptionLabel}
          options={options}
          optionIdKey={optionIdKey}
          optionLabelKey={optionLabelKey}
          error={error}
        />
      )}
      renderTags={handleRenderTags}
    />
  );
}

SearchableSelect.displayName = NAME;

SearchableSelect.propTypes = {
  defaultValues: PropTypes.oneOfType([PropTypes.array, PropTypes.string, PropTypes.object]),
  error: PropTypes.string,
  helperText: PropTypes.string,
  InputLabelProps: PropTypes.object,
  isClearable: PropTypes.bool,
  isDisabled: PropTypes.bool,
  isLoading: PropTypes.bool,
  mode: PropTypes.object,
  multiple: PropTypes.bool,
  name: PropTypes.string.isRequired,
  onBlur: PropTypes.func,
  onChange: PropTypes.func.isRequired,
  onOpen: PropTypes.func,
  optionIdKey: PropTypes.string,
  optionLabelKey: PropTypes.string,
  options: PropTypes.array,
  TextFieldProps: PropTypes.object,
  value: PropTypes.any
};

export default SearchableSelect;
