# frozen_string_literal: true

family_members_section_fields = [
  Field.new(name: 'relation_name',
            type: 'text_field',
            display_name_en: 'Name',
            matchable: true),
  Field.new(name: 'family_relationship',
            type: 'select_box',
            display_name_en: 'What is their role in the family?',
            option_strings_source: 'lookup lookup-family-relationship',
            matchable: true,
            help_text_en: 'This field can be copied to/from the Case but is not s shared field and '\
                          'can be edited on the Family record.'),
  Field.new(name: 'family_relationship_notes',
            type: 'textarea',
            display_name_en: 'Notes on their role in the family.',
            matchable: true,
            help_text_en: 'This field is not shared with the case records.'),
  Field.new(name: 'family_relationship_additional_notes',
            type: 'textarea',
            display_name_en: 'Additional notes on the family member.',
            matchable: true,
            help_text_en: 'This field is not shared with the case records.'),
  Field.new(name: 'relation_identifiers',
            type: 'text_field',
            display_name_en: 'List any agency identifiers as a comma separated list',
            visible: false,
            mobile_visible: false),
  Field.new(name: 'relation_nickname',
            type: 'text_field',
            display_name_en: 'Other names or spellings known by',
            matchable: true,
            help_text_en: 'e.g., nickname, second family name'),
  Field.new(name: 'relation_is_alive',
            type: 'select_box',
            display_name_en: 'Is this family member alive?',
            option_strings_text_en: [
              { id: 'unknown', display_text: 'Unknown' },
              { id: 'alive', display_text: 'Alive' },
              { id: 'dead', display_text: 'Dead' }
            ].map(&:with_indifferent_access)),
  Field.new(name: 'relation_death_details',
            type: 'textarea',
            display_name_en: 'If dead, please provide details',
            help_text_en: 'Include date of death if known '),
  Field.new(name: 'relation_age',
            type: 'numeric_field',
            display_name_en: 'Age'),
  Field.new(name: 'relation_date_of_birth',
            type: 'date_field',
            display_name_en: 'Date of Birth',
            date_validation: 'not_future_date'),
  Field.new(name: 'relation_sex',
            type: 'select_box',
            display_name_en: 'Sex',
            option_strings_source: 'lookup lookup-gender'),
  Field.new(name: 'relation_age_estimated',
            type: 'tick_box',
            tick_box_label_en: 'Yes',
            display_name_en: 'Is the age estimated?'),
  Field.new(name: 'relation_national_id',
            type: 'text_field',
            display_name_en: 'National ID'),
  Field.new(name: 'relation_unhcr_individual_id',
            type: 'text_field',
            display_name_en: 'UNHCR Individual ID'),
  Field.new(name: 'relation_other_id',
            type: 'text_field',
            display_name_en: 'Other ID'),
  Field.new(name: 'relation_language',
            type: 'select_box',
            display_name_en: 'Language',
            multi_select: true,
            option_strings_source: 'lookup lookup-language',
            matchable: true,
            visible: false,
            mobile_visible: false),
  Field.new(name: 'relation_religion',
            type: 'select_box',
            display_name_en: 'Religion',
            multi_select: true,
            option_strings_source: 'lookup lookup-religion',
            matchable: true,
            visible: false,
            mobile_visible: false),
  Field.new(name: 'relation_ethnicity',
            type: 'select_box',
            display_name_en: 'Ethnicity',
            option_strings_source: 'lookup lookup-ethnicity',
            matchable: true),
  Field.new(name: 'relation_sub_ethnicity1',
            type: 'select_box',
            display_name_en: 'Sub Ethnicity 1',
            option_strings_source: 'lookup lookup-ethnicity'),
  Field.new(name: 'relation_sub_ethnicity2',
            type: 'select_box',
            display_name_en: 'Sub Ethnicity 2',
            option_strings_source: 'lookup lookup-ethnicity'),
  Field.new(name: 'relation_nationality',
            type: 'select_box',
            display_name_en: 'Nationality',
            multi_select: true,
            option_strings_source: 'lookup lookup-country',
            matchable: true,
            visible: false,
            mobile_visible: false),
  Field.new(name: 'relation_comments',
            type: 'textarea',
            display_name_en: 'Comments',
            visible: false,
            mobile_visible: false),
  Field.new(name: 'relation_occupation',
            type: 'text_field',
            display_name_en: 'Occupation'),
  Field.new(name: 'relation_address_current',
            type: 'textarea',
            display_name_en: 'Current Address (if different from the child)',
            matchable: true),
  Field.new(name: 'relation_address_is_permanent',
            type: 'tick_box',
            display_name_en: 'Is this a permanent location?',
            visible: false,
            mobile_visible: false),
  Field.new(name: 'relation_landmark_current',
            type: 'text_field',
            display_name_en: 'Current Landmark'),
  Field.new(name: 'relation_location_current',
            type: 'select_box',
            display_name_en: 'Current Location',
            option_strings_source: 'Location',
            matchable: true),
  Field.new(name: 'relation_address_last',
            type: 'textarea',
            display_name_en: 'Last Known Address',
            visible: false,
            mobile_visible: false,
            help_text_en: 'If separated from child, last known address'),
  Field.new(name: 'relation_location_last',
            type: 'select_box',
            display_name_en: 'Last Known Location',
            option_strings_source: 'Location',
            visible: false,
            mobile_visible: false,
            help_text_en: 'If separated from child, last known address'),
  Field.new(name: 'relation_telephone',
            type: 'text_field',
            display_name_en: 'Telephone / other contact details',
            matchable: true)
]

family_members_section = FormSection.create_or_update!(
  visible: false,
  is_nested: true,
  mobile_form: true,
  order_form_group: 50,
  order: 10,
  order_subform: 1,
  unique_id: 'family_members_section',
  parent_form: 'family',
  editable: true,
  fields: family_members_section_fields,
  initial_subforms: 1,
  name_en: 'Nested Family Members',
  description_en: 'Family Members Subform',
  collapsed_field_names: %w[relation_name]
)

family_members_fields = [
  Field.new(name: 'family_number',
            type: 'text_field',
            display_name_en: 'Family Number'),
  Field.new(name: 'family_size',
            type: 'numeric_field',
            display_name_en: 'Size of Family'),
  Field.new(name: 'family_notes',
            type: 'textarea',
            display_name_en: 'Notes on Family'),
  Field.new(name: 'family_notes_additional',
            type: 'textarea',
            display_name_en: 'Additional Notes on the family',
            help_text_en: 'Additional notes on the family not shared with the associated case records.'),
  # #Subform##
  Field.new(name: 'family_members',
            type: 'subform',
            editable: true,
            subform_section: family_members_section,
            display_name_en: 'Family Member')
  # #Subform##
]

FormSection.create_or_update!(
  unique_id: 'family_members',
  parent_form: 'family',
  visible: true,
  order_form_group: 30,
  order: 20,
  order_subform: 0,
  form_group_id: 'family_overview',
  editable: true,
  fields: family_members_fields,
  name_en: 'Family Members',
  description_en: 'Family Members',
  mobile_form: true
)
