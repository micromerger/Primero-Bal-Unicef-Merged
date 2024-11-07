# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

# Class for Reportable Follow Up
class ReportableFollowUp
  include ReportableNestedRecord

  def self.parent_record_type
    Child
  end

  def self.record_field_name
    'followup_subform_section'
  end

  def self.report_filters
    [
      { 'attribute' => 'status', 'value' => [Record::STATUS_OPEN] },
      { 'attribute' => 'record_state', 'value' => ['true'] },
      { 'attribute' => 'followup_date', 'constraint' => 'not_null' }

    ]
  end

  def id
    object_value('unique_id')
  end
end
