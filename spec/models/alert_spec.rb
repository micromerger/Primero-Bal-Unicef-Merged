# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

require 'rails_helper'

describe Alert do
  describe 'duplicate alerts' do
    before :each do
      clean_data(Alert, Child)

      @child1 = Child.create!(data: { field_id: '0001' })
      @child2 = Child.create!(data: { field_id: '0001' })
      @child3 = Child.create!(data: { field_id: '0002' })
      Alert.create!(alert_for: DuplicateIdAlertable::DUPLICATE_FIELD, type: 'field_id', record: @child1)
      Alert.create!(alert_for: DuplicateIdAlertable::DUPLICATE_FIELD, type: 'field_id', record: @child3)
    end

    it 'remove duplicate alerts for records with the same value' do
      Alert.create!(alert_for: DuplicateIdAlertable::DUPLICATE_FIELD, type: 'field_id', record: @child2)

      expect(Alert.count).to eq(2)
      expect(Alert.all.map { |alert| alert.record.id }).to match_array([@child2.id, @child3.id])
    end
  end

  describe 'email alerts' do
    before :each do
      clean_data(User, Role, PrimeroModule, PrimeroProgram, Field, FormSection, UserGroup, Agency, Alert,
                 SystemSettings, Child)
      ss = SystemSettings.create!
      ss.changes_field_to_form = {
        'email_alertable_field' => {
          form_section_unique_id: 'some_formsection_name1',
          alert_strategy: Alertable::AlertStrategy::ASSOCIATED_USERS
        }
      }
      ss.save!
      @owner = create :user, user_name: 'owner', full_name: 'Owner', email: 'owner@primero.dev'
      @provider = create :user, user_name: 'provider', full_name: 'Provider', email: 'provider@primero.dev'
    end
    it 'creates an email alert' do
      child = Child.new(data: { 'email_alertable_field' => 'some_value' })
      child.save!
      expect(Alert.count).to eq(1)
    end
    it 'does not create an email alert on other fields' do
      child = Child.new(data: { 'some_other_field' => 'some_value' })
      child.save!
      expect(Alert.count).to eq(0)
    end
    it 'deletes the old alert when a duplicate alert is created' do
      child = Child.new(data: { 'email_alertable_field' => 'some_value' })
      child.save!
      expect(Alert.count).to eq(1)
      old_alert = Alert.first
      child.data['email_alertable_field'] = 'some_other_value'
      child.save!
      expect(Alert.count).to eq(1)
      expect(Alert.first.unique_id).not_to eq(old_alert.unique_id)
    end
  end
end
