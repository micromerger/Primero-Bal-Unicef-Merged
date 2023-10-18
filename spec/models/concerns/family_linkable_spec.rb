# frozen_string_literal: true

require 'rails_helper'

describe FamilyLinkable do
  before(:each) { clean_data(User, Child, Family) }

  let(:user) do
    user = User.new(user_name: 'user_cp', full_name: 'Test User CP')
    user.save(validate: false) && user
  end

  let(:family2) do
    family = Family.new_with_user(
      user,
      {
        family_number: '5fba4918',
        family_members: [
          { 'unique_id' => 'f5775818', 'relation_sex' => 'male' },
          { 'unique_id' => '14397418', 'relation_sex' => 'female' }
        ]
      }
    )
    family.save!
    family
  end

  let(:child) do
    child = Child.new_with_user(user, { age: 5, sex: 'male' })
    child.family = family2
    child.family_member_id = 'f5775818'
    child.family_details_section = [
      { 'unique_id' => 'f5775818' },
      { 'unique_id' => '14397418', 'relation' => 'mother', 'relation_name' => 'Name1' }
    ]
    child.save!
    child
  end

  describe 'family_members_details' do
    it 'returns fields from family members and family details not including itself' do
      expect(child.family_members_details).to eq(
        [{ 'unique_id' => '14397418', 'relation' => 'mother', 'relation_sex' => 'female', 'relation_name' => 'Name1' }]
      )
    end

    it 'updates the family_members and does not change the family_details_section' do
      child.update_properties(
        user,
        {
          'family_details_section' => [
            { 'unique_id' => 'f5775818' },
            { 'unique_id' => '14397418', 'relation_name' => 'Name2' }
          ]
        }
      )
      child.save!
      child.reload

      expect(
        child.family_members_details.find { |member| member['unique_id'] == '14397418' }['relation_name']
      ).to eq('Name2')
      expect(
        child.family_details_section.find { |member| member['unique_id'] == '14397418' }['relation_name']
      ).to eq('Name1')
    end

    it 'updates the local family_details_section fields and does not change the family_members' do
      child.update_properties(
        user,
        {
          'family_details_section' => [
            { 'unique_id' => 'f5775818' },
            { 'unique_id' => '14397418', 'relation' => 'father' }
          ]
        }
      )
      child.save!
      child.reload

      expect(
        child.family.family_members.find { |member| member['unique_id'] == '14397418' }['relation']
      ).to be_nil
      expect(
        child.family_details_section.find { |member| member['unique_id'] == '14397418' }['relation']
      ).to eq('father')
    end
  end

  describe 'disassociate_from_family' do
    it 'disassociates a case from a family record' do
      child.update_properties(user, { 'family_id' => nil })
      child.save!

      family2.reload

      expect(child.family).to be_nil
      expect(child.family_member_id).to be_nil
      expect(family2.cases).to be_empty
      expect(family2.family_members.find { |member| member['case_id'] == child.id }).to be_nil
    end
  end
end
