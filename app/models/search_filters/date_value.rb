# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

# Transform API query parameter field_name=value into a sql query
class SearchFilters::DateValue < SearchFilters::Value
  def query
    ActiveRecord::Base.sanitize_sql_for_conditions(
      [
        %(
          to_timestamp(data->> :field_name, :date_format)
          #{@safe_operator}
          to_timestamp(:value, :date_format)
        ),
        { field_name:, value: value.iso8601, date_format: }
      ]
    )
  end

  def date_format
    date_include_time? ? Report::DATE_TIME_FORMAT : Report::DATE_FORMAT
  end

  def date_include_time?
    value.is_a?(Time)
  end
end