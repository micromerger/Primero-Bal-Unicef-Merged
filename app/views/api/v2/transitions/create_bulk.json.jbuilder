# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

json.data do
  json.array! @transitions do |transition|
    json.partial! 'api/v2/transitions/transition',
                  transition:,
                  updates_for_record: @updated_field_names_hash[transition.record_id]
  end
end
if @errors.present?
  json.errors do
    json.array! @errors do |error|
      json.partial! 'api/v2/errors/error', error:
    end
  end
end
