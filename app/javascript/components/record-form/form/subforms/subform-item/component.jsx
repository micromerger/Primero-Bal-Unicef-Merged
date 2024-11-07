// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";

import { useI18n } from "../../../../i18n";
import SubformTraces from "../subform-traces";

import { buildFormViolations } from "./utils";
import { NAME } from "./constants";

function Component({
  arrayHelpers,
  dialogIsNew,
  field,
  formik,
  forms,
  formSection,
  index,
  isDisabled,
  isTraces,
  isReadWriteForm,
  isViolation,
  isViolationAssociation,
  isFamilyDetail,
  isFamilyMember,
  mode,
  open,
  orderedValues,
  parentTitle,
  recordModuleID,
  recordType,
  selectedValue,
  setOpen,
  title,
  violationOptions,
  components
}) {
  const i18n = useI18n();
  const handleClose = () => setOpen(false);

  const fieldToRender = isViolation ? buildFormViolations(field, forms) : field;

  if (isTraces && mode.isShow) {
    return (
      <SubformTraces
        formSection={formSection}
        openDrawer={open}
        handleClose={handleClose}
        field={field}
        formik={formik}
        index={index}
        recordType={recordType}
        mode={mode}
      />
    );
  }

  return (
    <components.SubformDialog
      components={components}
      arrayHelpers={arrayHelpers}
      dialogIsNew={dialogIsNew}
      field={fieldToRender}
      formik={formik}
      i18n={i18n}
      index={index}
      isFormShow={mode.isShow || isDisabled || isReadWriteForm === false}
      mode={mode}
      oldValue={!dialogIsNew ? selectedValue : {}}
      open={open}
      setOpen={setOpen}
      title={title}
      formSection={formSection}
      isReadWriteForm={isReadWriteForm}
      orderedValues={orderedValues}
      recordType={recordType}
      recordModuleID={recordModuleID}
      isFamilyDetail={isFamilyDetail}
      isFamilyMember={isFamilyMember}
      isViolation={isViolation}
      isViolationAssociation={isViolationAssociation}
      parentTitle={parentTitle}
      violationOptions={violationOptions}
    />
  );
}

Component.displayName = NAME;

Component.propTypes = {
  arrayHelpers: PropTypes.object.isRequired,
  components: PropTypes.objectOf({
    SubformItem: PropTypes.elementType.isRequired,
    SubformDialog: PropTypes.elementType.isRequired,
    SubformDialogFields: PropTypes.elementType.isRequired,
    SubformFieldSubform: PropTypes.elementType.isRequired,
    SubformField: PropTypes.elementType.isRequired
  }),
  dialogIsNew: PropTypes.bool.isRequired,
  field: PropTypes.object.isRequired,
  formik: PropTypes.object.isRequired,
  forms: PropTypes.object.isRequired,
  formSection: PropTypes.object,
  index: PropTypes.number,
  isDisabled: PropTypes.bool,
  isFamilyDetail: PropTypes.bool,
  isFamilyMember: PropTypes.bool,
  isReadWriteForm: PropTypes.bool,
  isTraces: PropTypes.bool,
  isViolation: PropTypes.bool,
  isViolationAssociation: PropTypes.bool,
  mode: PropTypes.object.isRequired,
  open: PropTypes.bool,
  orderedValues: PropTypes.array.isRequired,
  parentTitle: PropTypes.string,
  recordModuleID: PropTypes.string,
  recordType: PropTypes.string,
  selectedValue: PropTypes.object,
  setOpen: PropTypes.func.isRequired,
  title: PropTypes.string,
  violationOptions: PropTypes.array
};

export default Component;
