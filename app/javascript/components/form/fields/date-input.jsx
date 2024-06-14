// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

/* eslint-disable react/display-name, react/no-multi-comp */
import PropTypes from "prop-types";
import { Controller, useWatch } from "react-hook-form";
import isEmpty from "lodash/isEmpty";
import { parseISO } from "date-fns";
import { AdapterDateFns } from "@mui/x-date-pickers/AdapterDateFns";
import { DatePicker, DateTimePicker, LocalizationProvider } from "@mui/x-date-pickers";

import { toServerDateFormat } from "../../../libs";
import { useI18n } from "../../i18n";
import localize from "../../../libs/date-picker-localization";
import { LOCALE_KEYS } from "../../../config";
import NepaliCalendar from "../../nepali-calendar-input";

function DateInput({ commonInputProps, metaInputProps = {}, formMethods }) {
  const i18n = useI18n();
  const { setValue, control } = formMethods;
  const { name, label, helperText, error, disabled, placeholder, fullWidth, required } = commonInputProps;

  const currentValue = useWatch({ name, control });

  const dialogLabels = {
    clearLabel: i18n.t("buttons.clear"),
    cancelLabel: i18n.t("buttons.cancel"),
    okLabel: i18n.t("buttons.ok")
  };

  const { dateIncludeTime } = metaInputProps;

  const handleChange = date => {
    setValue(name, date ? toServerDateFormat(date, { includeTime: dateIncludeTime }) : "", { shouldDirty: true });

    return date;
  };

  const neDateProps = {
    name,
    onChange: handleChange,
    error,
    disabled,
    placeholder,
    dateIncludeTime,
    value: currentValue
  };

  const fieldValue = isEmpty(currentValue) ? null : parseISO(currentValue);

  const inputProps = {
    slotProps: { textField: { InputLabelProps: { shrink: true }, fullWidth, required, helperText } }
  };

  const renderPicker = () => {
    if (dateIncludeTime) {
      return (
        <DateTimePicker
          {...dialogLabels}
          {...commonInputProps}
          {...inputProps}
          onChange={handleChange}
          value={fieldValue}
        />
      );
    }

    return (
      <DatePicker {...dialogLabels} {...commonInputProps} {...inputProps} onChange={handleChange} value={fieldValue} />
    );
  };

  if (i18n.locale === LOCALE_KEYS.ne) {
    return <NepaliCalendar helpText={helperText} label={label} dateProps={neDateProps} />;
  }

  return (
    <LocalizationProvider dateAdapter={AdapterDateFns} adapterLocale={localize(i18n)}>
      <Controller
        control={control}
        as={renderPicker}
        {...commonInputProps}
        helperText={<>{helperText}</>}
        defaultValue=""
      />
    </LocalizationProvider>
  );
}

DateInput.displayName = "DateInput";

DateInput.propTypes = {
  commonInputProps: PropTypes.object.isRequired,
  formMethods: PropTypes.object.isRequired,
  metaInputProps: PropTypes.object
};

export default DateInput;
