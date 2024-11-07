// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";
import { cx } from "@emotion/css";
import { Draggable } from "react-beautiful-dnd";
import { Controller, useWatch } from "react-hook-form";
import { Radio } from "@mui/material";
import get from "lodash/get";
import DeleteIcon from "@mui/icons-material/Delete";
import IconButton from "@mui/material/IconButton";

import TextInput from "../../fields/text-input";
import SwitchInput from "../../fields/switch-input";
import css from "../../fields/styles.css";
import DragIndicator from "../../../pages/admin/forms-list/components/drag-indicator";
import { generateIdFromDisplayText } from "../../utils/handle-options";

import textInputCss from "./styles.css";
import { NAME } from "./constants";

function Component({
  defaultOptionId,
  index,
  name,
  option,
  onRemoveClick,
  formMethods,
  formMode,
  showDefaultAction = true,
  showDeleteAction = true,
  showDisableOption = true,
  optionFieldName = "option_strings_text"
}) {
  const {
    errors,
    setValue,
    formState: { isDirty },
    control
  } = formMethods;
  const displayTextFieldName = `${name}.${optionFieldName}[${index}].display_text.en`;
  const idFieldName = `${name}.${optionFieldName}[${index}].id`;
  const selectedValueFieldName = `${name}.selected_value`;

  const optionId = useWatch({ control, name: `${name}.${optionFieldName}[${index}].id`, defaultValue: option.id });
  const disabledValue = useWatch({
    control,
    name: `${name}.${optionFieldName}[${index}].disabled`,
    defaultValue: option?.disabled
  });
  const selectedValue = useWatch({ control, name: `${name}.selected_value`, defaultValue: defaultOptionId });

  const error = errors ? get(errors, displayTextFieldName) : undefined;

  const handleChange = event => {
    const { value } = event.currentTarget;
    const newOptionId = generateIdFromDisplayText(value);

    if (isDirty && value && option.isNew) {
      setValue(idFieldName, newOptionId, { shouldDirty: true });

      if (selectedValue === optionId) {
        setValue(selectedValueFieldName, newOptionId, { shouldDirty: true });
      }
    }

    return value;
  };

  const renderCheckbox = formMode.get("isEdit") && showDisableOption && (
    <SwitchInput
      commonInputProps={{ name: `${name}.option_strings_text[${index}].disabled` }}
      metaInputProps={{ selectedValue: disabledValue }}
      formMethods={formMethods}
    />
  );

  const handleRemoveClick = () => onRemoveClick(index);

  const renderRemoveButton = formMode.get("isNew") && showDeleteAction && (
    <IconButton size="large" aria-label="delete" className={css.removeIcon} onClick={handleRemoveClick}>
      <DeleteIcon />
    </IconButton>
  );
  const classesDragIndicator = cx([css.fieldColumn, css.dragIndicatorColumn]);
  const classesTextInput = cx([css.fieldColumn, css.fieldInput]);
  const handleOnBlur = event => handleChange(event, index);

  return (
    <Draggable draggableId={option.fieldID} index={index}>
      {provided => (
        <div ref={provided.innerRef} {...provided.draggableProps}>
          <div className={css.fieldRow}>
            <div className={classesDragIndicator}>
              <DragIndicator {...provided.dragHandleProps} />
            </div>
            <div className={classesTextInput}>
              <TextInput
                formMethods={formMethods}
                commonInputProps={{
                  name: displayTextFieldName,
                  className: css.inputOptionField,
                  error: typeof error !== "undefined",
                  helperText: error?.message,
                  // eslint-disable-next-line camelcase
                  defaultValue: option?.display_text?.en,
                  InputProps: {
                    classes: { disabled: textInputCss.disabled },
                    onBlur: handleOnBlur
                  }
                }}
              />
              <input
                className={css.displayNone}
                type="text"
                name={idFieldName}
                ref={formMethods.register}
                defaultValue={option.id}
              />
            </div>
            {showDefaultAction && (
              <div className={css.fieldColumn}>
                <Controller
                  control={control}
                  as={<Radio />}
                  inputProps={{ value: optionId }}
                  checked={optionId === selectedValue}
                  name={`${name}.selected_value`}
                  defaultValue={false}
                />
              </div>
            )}
            {((formMode.get("isNew") && showDeleteAction) || showDisableOption) && (
              <div className={css.fieldColumn}>
                {renderCheckbox}
                {renderRemoveButton}
              </div>
            )}
          </div>
        </div>
      )}
    </Draggable>
  );
}

Component.propTypes = {
  defaultOptionId: PropTypes.string,
  disabled: PropTypes.bool,
  formMethods: PropTypes.object.isRequired,
  formMode: PropTypes.object.isRequired,
  index: PropTypes.number,
  name: PropTypes.string.isRequired,
  onRemoveClick: PropTypes.func,
  option: PropTypes.object,
  optionFieldName: PropTypes.string,
  showDefaultAction: PropTypes.bool,
  showDeleteAction: PropTypes.bool,
  showDisableOption: PropTypes.bool
};

Component.displayName = NAME;

export default Component;
