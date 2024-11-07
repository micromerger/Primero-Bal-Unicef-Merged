# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

require 'rails_helper'

describe ApprovalRequestNotificationService do
  before do
    clean_data(
      FormSection, PrimeroModule, PrimeroProgram, UserGroup,
      User, Agency, Role, Child, Transition, Lookup
    )

    Lookup.create!(
      unique_id: 'lookup-approval-type',
      name: 'approval type',
      lookup_values_en: [{ 'id' => 'value1', 'display_text' => 'Value 1' }]
    )

    SystemSettings.stub(:current).and_return(
      SystemSettings.new(
        approvals_labels_i18n: {
          'en' => {
            'closure' => 'Closure',
            'case_plan' => 'Case Plan',
            'assessment' => 'Assessment',
            'action_plan' => 'Action Plan',
            'gbv_closure' => 'Case Closure'
          }
        }
      )
    )
  end

  let(:role) do
    create(:role, is_manager: true)
  end

  let(:user) do
    create :user, user_name: 'user', full_name: 'Test User 1', email: 'owner@primero.dev'
  end

  let(:child) do
    create(:child, name: 'Test', owned_by: user.user_name, conssent_for_services: true, disclosure_other_orgs: true)
  end

  let(:manager) do
    create(:user, role:, email: 'manager@primero.dev', user_name: 'manager', receive_webpush: true, locale: :es)
  end

  subject do
    ApprovalRequestNotificationService.new(child.id, 'action_plan', manager.user_name)
  end

  describe '.locale' do
    it 'return manager locale' do
      expect(subject.locale).to eq(manager.locale)
    end
  end

  describe '.manager' do
    it 'return manager' do
      expect(subject.manager.user_name).to eq(manager.user_name)
    end
  end

  describe '.child' do
    it 'return child' do
      expect(subject.child.short_id).to eq(child.short_id)
    end
  end

  describe '.approval_type' do
    it 'return approval_type' do
      expect(subject.approval_type).to eq('Action Plan')
    end
  end

  describe '.send_notification?' do
    it 'return true if notification can be send' do
      expect(subject.send_notification?).to be true
    end
  end

  describe '.subject' do
    it 'return child' do
      expect(subject.subject).to eq("Caso: #{child.short_id} - Solicitud de Aprobación")
    end
  end

  describe '.key' do
    it 'return approval_request' do
      expect(subject.key).to eq('approval_request')
    end
  end

  after do
    clean_data(
      FormSection, PrimeroModule, PrimeroProgram, UserGroup,
      User, Agency, Role, Child, Transition, Lookup
    )
  end
end
