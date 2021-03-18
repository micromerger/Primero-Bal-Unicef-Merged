/* eslint-disable import/prefer-default-export, camelcase */
import { fromJS } from "immutable";

import { FieldRecord, FormSectionRecord, CHECK_BOX_FIELD } from "../../../form";
import { displayNameHelper } from "../../../../libs";

const buildConsentAgreementFields = (i18n, consentAgreementFields = []) => {
  const fields = consentAgreementFields.map((field, index) => {
    return {
      id: field.name,
      display_name: displayNameHelper(field.display_name, i18n.locale),
      includeSeparator: index !== 0
    };
  });

  return fields;
};

const buildLegitimateFields = (legitimateBasisLookup, legitimateBasisExplanationsLookup) => {
  const fields = legitimateBasisLookup.reduce((acc, legitimateBasis, index) => {
    const legitimateBasisId = legitimateBasis.id;
    const legitimateBasisText = legitimateBasis.display_text;
    const legitimateBasisExplanation = legitimateBasisExplanationsLookup.find(
      explanation => explanation.id === legitimateBasisId
    )?.display_text;

    const boldText = <b>{legitimateBasisText}</b>;

    const displayName = (
      <p>
        {boldText} {legitimateBasisExplanation ? `: ${legitimateBasisExplanation}` : null}
      </p>
    );

    return [
      ...acc,
      {
        id: legitimateBasisId,
        display_name: () => displayName,
        includeSeparator: index !== 0
      }
    ];
  }, []);

  return fields;
};

export const consentPromptForm = (
  i18n,
  {
    renderConsentAgreementField,
    renderLegitimateField,
    consentAgreementFields,
    legitimateBasisLookup,
    legitimateBasisExplanationsLookup
  }
) =>
  fromJS([
    FormSectionRecord({
      unique_id: "consent_form",
      fields: [
        FieldRecord({
          display_name: i18n.t("case.consent_agreements"),
          name: "consent_agreements",
          type: CHECK_BOX_FIELD,
          visible: renderConsentAgreementField,
          option_strings_text: buildConsentAgreementFields(i18n, consentAgreementFields)
        }),
        FieldRecord({
          display_name: i18n.t("case.legitimate_basis"),
          name: "legitimate_basis",
          type: CHECK_BOX_FIELD,
          visible: renderLegitimateField,
          option_strings_text: buildLegitimateFields(legitimateBasisLookup, legitimateBasisExplanationsLookup)
        })
      ]
    })
  ]);