# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

fields = [
  Field.new(name: 'record_state',
            type: 'tick_box',
            editable: false,
            disabled: true,
            display_name_en: 'Valid Record?'),
  Field.new(name: 'owned_by',
            type: 'select_box',
            option_strings_source: 'User',
            disabled: true,
            display_name_en: 'Record Owner'),
  Field.new(name: 'owned_by_agency_id',
            type: 'select_box',
            display_name_en: "Record Owner's Agency",
            editable: false,
            disabled: true,
            option_strings_source: 'Agency'),
  Field.new(name: 'owned_by_location',
            type: 'select_box',
            display_name_en: "Record Owner's Location",
            editable: false,
            disabled: true,
            option_strings_source: 'Location'),
  Field.new(name: 'created_at',
            type: 'date_field',
            editable: false,
            disabled: true,
            display_name_en: 'Created at',
            date_include_time: true),
  Field.new(name: 'created_by',
            type: 'text_field',
            editable: false,
            disabled: true,
            display_name_en: 'Record created by'),
  Field.new(name: 'created_organization',
            type: 'select_box',
            disabled: true,
            option_strings_source: 'Agency',
            display_name_en: 'Created by agency')
]

FormSection.create_or_update!(
  unique_id: 'other_reportable_fields_family',
  parent_form: 'family',
  visible: false,
  order: 1000,
  order_form_group: 1000,
  form_group_id: 'other_reportable_fields',
  editable: true,
  fields:,
  name_en: 'Other Reportable Fields',
  description_en: 'Other Reportable Fields'
)
