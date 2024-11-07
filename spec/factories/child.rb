# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

FactoryBot.define do
  factory :child, class: Child, traits: [:record] do
    unique_identifier { counter.to_s }
    name              { "Test Child #{counter}" }
    created_by        { 'test_user' }
    owned_by          { 'test_user' }
    module_id         { 'primeromodule-cp' }
    status { Record::STATUS_OPEN }
    case_id_display { 'display_1234' }

    transient do
      sequence(:counter, 1_000_000)
    end

    initialize_with do
      if attributes[:id].present?
        id = attributes.delete(:id)
        new(id:, data: attributes)
      else
        new(data: attributes)
      end
    end
  end
end
