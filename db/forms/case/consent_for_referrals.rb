consent_for_referrals_fields = [
  Field.new({"name" => "consent_release_separator",
             "show_on_minify_form" => true,
             "mobile_visible" => true,
             "type" => "separator",
             "display_name_en" => "Consent to Release Information by Referral Type",
            }),
  Field.new({"name" => "consent_to_share_info_by_security",
             "show_on_minify_form" => true,
             "mobile_visible" => true,
             "type" => "radio_button",
             "display_name_en" => "Consent to Release Information to Security Services",
             "option_strings_source" => "lookup lookup-yes-no"
            }),
  Field.new({"name" => "consent_to_share_security_organization",
             "mobile_visible" => true,
             "type" => "text_field",
             "display_name_en" => "Specify Security Name, Facility or Agency/Organization as applicable"
            }),
  Field.new({"name" => "consent_to_share_info_by_psychosocial",
             "show_on_minify_form" => true,
             "mobile_visible" => true,
             "type" => "radio_button",
             "display_name_en" => "Consent to Release Information to Psychosocial Services",
             "option_strings_source" => "lookup lookup-yes-no"
            }),
  Field.new({"name" => "consent_to_share_psychosocial_organization",
             "mobile_visible" => true,
             "type" => "text_field",
             "display_name_en" => "Specify Psychosocial Name, Facility or Agency/Organization as applicable"
            }),
  Field.new({"name" => "consent_to_share_info_by_health",
             "show_on_minify_form" => true,
             "mobile_visible" => true,
             "type" => "radio_button",
             "display_name_en" => "Consent to Release Information to Health/Medical Services",
             "option_strings_source" => "lookup lookup-yes-no"
            }),
  Field.new({"name" => "consent_to_share_health_organization",
             "mobile_visible" => true,
             "type" => "text_field",
             "display_name_en" => "Specify Health/Medical Name, Facility or Agency/Organization as applicable"
            }),
  Field.new({"name" => "consent_to_share_info_by_safehouse",
             "show_on_minify_form" => true,
             "mobile_visible" => true,
             "type" => "radio_button",
             "display_name_en" => "Consent to Release Information to Safe House/Shelter",
             "option_strings_source" => "lookup lookup-yes-no"
            }),
  Field.new({"name" => "consent_to_share_safehouse_organization",
             "mobile_visible" => true,
             "type" => "text_field",
             "display_name_en" => "Specify Safe House/Shelter Name, Facility or Agency/Organization as applicable"
            }),
  Field.new({"name" => "consent_to_share_info_by_legal",
             "show_on_minify_form" => true,
             "mobile_visible" => true,
             "type" => "radio_button",
             "display_name_en" => "Consent to Release Information to Legal Assistance Services",
             "option_strings_source" => "lookup lookup-yes-no"
            }),
  Field.new({"name" => "consent_to_share_legal_organization",
             "mobile_visible" => true,
             "type" => "text_field",
             "display_name_en" => "Specify Legal Assistance Name, Facility or Agency/Organization as applicable"
            }),
  Field.new({"name" => "consent_to_share_info_by_protection",
             "show_on_minify_form" => true,
             "mobile_visible" => true,
             "type" => "radio_button",
             "display_name_en" => "Consent to Release Information to Protection Services",
             "option_strings_source" => "lookup lookup-yes-no"
            }),
  Field.new({"name" => "consent_to_share_protection_organization",
             "mobile_visible" => true,
             "type" => "text_field",
             "display_name_en" => "Specify Protection Services Name, Facility or Agency/Organization as applicable"
            }),
  Field.new({"name" => "consent_to_share_info_by_livelihoods",
             "show_on_minify_form" => true,
             "mobile_visible" => true,
             "type" => "radio_button",
             "display_name_en" => "Consent to Release Information to Livelihoods Services",
             "option_strings_source" => "lookup lookup-yes-no"
            }),
  Field.new({"name" => "consent_to_share_livelihoods_organization",
             "mobile_visible" => true,
             "type" => "text_field",
             "display_name_en" => "Specify Livelihoods Services Name, Facility or Agency/Organization as applicable"
            }),
  Field.new({"name" => "consent_to_share_info_by_other",
             "show_on_minify_form" => true,
             "mobile_visible" => true,
             "type" => "radio_button",
             "display_name_en" => "Consent to Release Information to Other Services",
             "option_strings_source" => "lookup lookup-yes-no"
            }),
  Field.new({"name" => "consent_to_share_info_by_other_details",
             "mobile_visible" => true,
             "type" => "text_field",
             "display_name_en" => "If other services, please specify service, name and agency"
            })
]

FormSection.create_or_update_form_section({
  unique_id: "consent_for_referrals",
  parent_form: "case",
  visible: true,
  order_form_group: 65,
  order: 10,
  order_subform: 0,
  form_group_name: "Consent for Referrals",
  editable: true,
  fields: consent_for_referrals_fields,
  mobile_form: true,
  name_en: "Consent for Referrals",
  description_en: "Consent for Referrals",
})