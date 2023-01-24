# frozen_string_literal: true

require 'rails_helper'

# TODO: add i18n tests
describe Report do
  before :all do
    clean_data(PrimeroProgram, PrimeroModule, FormSection, Field, Child)
    @module = create :primero_module
  end

  it 'must have a name' do
    r = Report.new(
      record_type: 'case', unique_id: 'report-test', aggregate_by: %w[a b], module_id: @module.unique_id
    )
    expect(r.valid?).to be_falsey
    r.name = 'Test'
    expect(r.valid?).to be_truthy
  end

  it "must have an 'aggregate_by' value" do
    r = Report.new(
      name: 'Test', unique_id: 'report-test', record_type: 'case', module_id: @module.unique_id
    )
    expect(r.valid?).to be_falsey
    r.aggregate_by = %w[a b]
    expect(r.valid?).to be_truthy
  end

  it 'must have a record type associated with itself' do
    r = Report.new(
      name: 'Test', aggregate_by: %w[a b], module_id: @module.unique_id, unique_id: 'report-test'
    )
    expect(r.valid?).to be_falsey
    r.record_type = 'case'
    expect(r.valid?).to be_truthy
  end

  it "doesn't point to invalid modules" do
    r = Report.new(
      name: 'Test', aggregate_by: %w[a b], module_id: 'nosuchmodule', unique_id: 'report-test'
    )
    expect(r.valid?).to be_falsey
  end

  it 'lists reportable record types' do
    expect(Report.reportable_record_types).to include('case', 'incident', 'tracing_request', 'violation')
  end

  describe 'nested reports' do
    it 'lists reportsable nested record types' do
      expect(Report.reportable_record_types).to include(
        'reportable_follow_up', 'reportable_protection_concern', 'reportable_service'
      )
    end

    it 'has default follow up filters' do
      r = Report.new(record_type: 'reportable_follow_up', add_default_filters: true)
      r.apply_default_filters
      expect(r.filters).to include('attribute' => 'followup_date', 'constraint' => 'not_null')
    end

    it 'has default service filters' do
      r = Report.new(record_type: 'reportable_service', add_default_filters: true)
      r.apply_default_filters
      expect(r.filters).to include(
        { 'attribute' => 'service_type', 'value' => 'not_null' },
        'attribute' => 'service_appointment_date', 'constraint' => 'not_null'
      )
    end

    it 'has default protection concern filters' do
      r = Report.new(record_type: 'reportable_protection_concern', add_default_filters: true)
      r.apply_default_filters
      expect(r.filters).to include('attribute' => 'protection_concern_type', 'value' => 'not_null')
    end

    it 'generates a unique id' do
      r = Report.create!(
        name: 'Test', record_type: 'case', aggregate_by: %w[a b], module_id: @module.unique_id
      )
      expect(r.unique_id).to match(/^report-test-[0-9a-f]{7}$/)
    end
  end

  describe 'modules_present' do
    it 'will reject the empty module_id list' do
      r = Report.new record_type: 'case', aggregate_by: %w[a b], module_id: ''
      expect(r.valid?).to be_falsey
      expect(r.errors[:module_id][0]).to eq(I18n.t('errors.models.report.module_presence'))
    end

    it 'will reject the invalid module_id list' do
      r = Report.new record_type: 'case', aggregate_by: %w[a b], module_id: 'badmoduleid'
      expect(r.valid?).to be_falsey
      expect(r.errors[:module_id][0]).to eq(I18n.t('errors.models.report.module_syntax'))
    end

    it 'will accept the valid module_id list' do
      r = Report.new record_type: 'case', aggregate_by: %w[a b], module_id: 'primeromodule-cp'
      expect(r.modules_present).to be_nil
    end
  end

  describe 'is_graph' do
    context 'when is_graph is in params' do
      before do
        @report = Report.new(name: 'Test', unique_id: 'report-test', record_type: 'case', module_id: @module.unique_id,
                             is_graph: true)
      end

      it 'has value for is_graph' do
        expect(@report.is_graph).to be_truthy
      end

      it 'has value for graph' do
        expect(@report.graph).to be_truthy
      end
    end

    context 'when graph is in params' do
      before do
        @report = Report.new(name: 'Test', unique_id: 'report-test', record_type: 'case', module_id: @module.unique_id,
                             graph: true)
      end

      it 'has value for is_graph' do
        expect(@report.is_graph).to be_truthy
      end

      it 'has value for graph' do
        expect(@report.graph).to be_truthy
      end
    end

    context 'when is_graph is updated' do
      before :each do
        @report = Report.new(name: 'Test', unique_id: 'report-test', record_type: 'case', module_id: @module.unique_id,
                             is_graph: false)
      end

      it 'updates is_graph' do
        expect(@report.is_graph).to be_falsey

        @report.update_properties(is_graph: true)
        expect(@report.is_graph).to be_truthy
      end

      it 'updates graph' do
        expect(@report.graph).to be_falsey

        @report.update_properties(is_graph: true)
        expect(@report.graph).to be_truthy
      end
    end

    context 'when graph is updated' do
      before :each do
        @report = Report.new(name: 'Test', unique_id: 'report-test', record_type: 'case', module_id: @module.unique_id,
                             graph: false)
      end

      it 'updates is_graph' do
        expect(@report.is_graph).to be_falsey

        @report.update_properties(graph: true)
        expect(@report.is_graph).to be_truthy
      end

      it 'updates graph' do
        expect(@report.graph).to be_falsey

        @report.update_properties(graph: true)
        expect(@report.graph).to be_truthy
      end
    end
  end

  describe 'exclude_empty_rows' do
    before :each do
      clean_data(FormSection, Field, Child, Lookup, Report)

      SystemSettings.stub(:current).and_return(
        SystemSettings.new(
          primary_age_range: 'primero',
          age_ranges: {
            'primero' => [0..5, 6..11, 12..17, 18..AgeRange::MAX],
            'unhcr' => [0..4, 5..11, 12..17, 18..59, 60..AgeRange::MAX]
          }
        )
      )

      Lookup.create!(
        unique_id: 'lookup-sex',
        name_en: 'sex',
        lookup_values_en: [
          { id: 'male', display_text: 'Male' },
          { id: 'female', display_text: 'Female' }
        ].map(&:with_indifferent_access)
      )

      Field.create!(
        name: 'sex', display_name: 'sex', type: Field::SELECT_BOX, option_strings_source: 'lookup lookup-sex'
      )

      Child.create!(data: { sex: 'female', module_id: @module.unique_id })
      Child.create!(data: { sex: 'female', module_id: @module.unique_id })
      Child.create!(data: { sex: 'female', module_id: @module.unique_id })
    end

    context 'when it is true' do
      before :each do
        @report = Report.new(
          name: 'Test',
          unique_id: 'report-test',
          record_type: 'case',
          module_id: @module.unique_id,
          graph: true,
          exclude_empty_rows: true,
          aggregate_by: ['sex'],
          disaggregate_by: []
        )
      end

      it 'should not return values with zero' do
        Child.where('data @> ?', { sex: 'male' }.to_json).destroy_all

        @report.build_report

        expect(@report.data).to eq('female' => { '_total' => 3 })
      end
    end

    context 'when it is false' do
      before :each do
        @report = Report.new(
          name: 'Test',
          unique_id: 'report-test',
          record_type: 'case',
          module_id: @module.unique_id,
          graph: true,
          exclude_empty_rows: false,
          aggregate_by: ['sex'],
          disaggregate_by: []
        )
      end

      it 'should return values with zero' do
        Child.where('data @> ?', { sex: 'male' }.to_json).destroy_all

        @report.build_report

        expect(@report.data).to eq('female' => { '_total' => 3 }, 'male' => { '_total' => 0 })
      end
    end
  end

  describe 'filter_query' do
    before :each do
      clean_data(FormSection, Field, Child, Lookup, Report)

      SystemSettings.stub(:current).and_return(
        SystemSettings.new(
          primary_age_range: 'primero',
          age_ranges: {
            'primero' => [0..5, 6..11, 12..17, 18..AgeRange::MAX],
            'unhcr' => [0..4, 5..11, 12..17, 18..59, 60..AgeRange::MAX]
          }
        )
      )

      Lookup.create!(
        unique_id: 'lookup-sex',
        name_en: 'sex',
        lookup_values_en: [
          { id: 'male', display_text: 'Male' },
          { id: 'female', display_text: 'Female' }
        ].map(&:with_indifferent_access)
      )

      Lookup.create!(
        unique_id: 'lookup-status',
        name_en: 'status',
        lookup_values_en: [
          { id: 'open', display_text: 'Open' },
          { id: 'closed', display_text: 'Closed' }
        ].map(&:with_indifferent_access)
      )

      Field.create!(
        name: 'sex', display_name: 'sex', type: Field::SELECT_BOX, option_strings_source: 'lookup lookup-sex'
      )

      Field.create!(
        name: 'status', display_name: 'status', type: Field::SELECT_BOX, option_strings_source: 'lookup lookup-status'
      )

      Child.create!(data: { status: 'closed', worklow: 'closed', sex: 'female', module_id: @module.unique_id })
      Child.create!(data: { status: 'closed', worklow: 'closed', sex: 'female', module_id: @module.unique_id })
      Child.create!(data: { status: 'open', worklow: 'open', sex: 'female', module_id: @module.unique_id })
      Child.create!(data: { status: 'closed', worklow: 'closed', sex: 'male', module_id: @module.unique_id })
    end

    context 'when it has filter' do
      before :each do
        @report = Report.new(
          name: 'Test',
          unique_id: 'report-test',
          record_type: 'case',
          module_id: @module.unique_id,
          graph: true,
          exclude_empty_rows: true,
          aggregate_by: ['sex'],
          disaggregate_by: [],
          filters: [
            {
              attribute: 'status',
              value: [
                'closed'
              ]
            }
          ]
        )
      end

      it 'should return 2 female and 1 male' do
        @report.build_report
        expect(@report.data).to eq('female' => { '_total' => 2 }, 'male' => { '_total' => 1 })
      end
    end

    context 'when it has a filter with two values' do
      before :each do
        @report = Report.new(
          name: 'Test - filter with two values',
          unique_id: 'report-test',
          record_type: 'case',
          module_id: @module.unique_id,
          graph: true,
          exclude_empty_rows: true,
          aggregate_by: %w[sex status],
          disaggregate_by: [],
          filters: [
            {
              attribute: 'status',
              value: %w[open closed]
            }
          ]
        )
      end

      it 'should return 3 female and 1 male total' do
        @report.build_report
        expect(@report.data).to eq(
          {
            'female' => { '_total' => 3, 'closed' => { '_total' => 2 }, 'open' => { '_total' => 1 } },
            'male' => { '_total' => 1, 'closed' => { '_total' => 1 } }
          }
        )
      end
    end
  end

  describe 'agency report scope', search: true do
    let(:agency) { Agency.create!(name: 'Test Agency', agency_code: 'TA1', services: ['Test type']) }
    let(:agency_with_space) do
      Agency.create!(name: 'Test Agency with Space', agency_code: 'TA TA', services: ['Test type'])
    end

    let(:case_worker) do
      user = User.new(user_name: 'case_worker', agency_id: agency.id)
      user.save(validate: false) && user
    end

    let(:service_provider) do
      user = User.new(
        user_name: 'service_provider', agency_id: agency_with_space.id)
      user.save(validate: false) && user
    end

    before(:each) do
      clean_data(User, Agency, Field, Lookup, Child, Report)
      Lookup.create!(
        unique_id: 'lookup-services',
        name_en: 'services',
        lookup_values_en: [
          { id: 'alternative_care', display_text: 'Alternative Care' }
        ].map(&:with_indifferent_access)
      )

      Field.create!(
        name: 'service_type',
        display_name: 'Service Type',
        type: Field::SELECT_BOX,
        option_strings_source: 'lookup lookup-services'
      )

      Field.create!(
        name: 'service_implemented',
        display_name: 'Service Implemented',
        type: Field::SELECT_BOX,
        option_strings_text_en: [
          { id: 'implemented', display_text: 'Implemented' }
        ]
      )

      Child.create!(
        data: {
          status: 'open', worklow: 'open', sex: 'female', module_id: @module.unique_id,
          services_section: [
            {
              unique_id: '1', service_type: 'alternative_care',
              service_implemented_day_time: Time.now,
              service_implementing_agency: 'AGENCY WITH SPACE',
              service_implementing_agency_individual: 'service_provider'
            }
          ],
          owned_by: case_worker.user_name,
          assigned_user_names: [service_provider.user_name]
        }
      )
    end

    let(:report) do
      Report.new(
        name: 'Services',
        record_type: 'reportable_service',
        module_id: @module.unique_id,
        aggregate_by: ['service_type'],
        disaggregate_by: ['service_implemented'],
        permission_filter: { 'attribute' => 'associated_user_agencies', 'value' => [agency_with_space.unique_id] }
      )
    end

    it 'can be seen by the agency scope even if the agency has blank spaces in it unique_id' do
      report.build_report
      expect(report.data).to eq({ 'alternative_care' => { '_total' => 1, 'implemented' => { '_total' => 1 } } })
    end
  end

  describe 'user group report scope', search: true do
    let(:group_1) { UserGroup.create!(name: 'Test User Group 1') }
    let(:group_2) { UserGroup.create!(name: 'Test User Group 2') }

    let(:case_worker_1) do
      user = User.new(user_name: 'case_worker_1', user_groups: [group_1])
      user.save(validate: false) && user
    end

    let(:case_worker_2) do
      user = User.new(user_name: 'case_worker_2', user_groups: [group_1, group_2])
      user.save(validate: false) && user
    end

    let(:case_worker_3) do
      user = User.new(user_name: 'case_worker_3', user_groups: [group_2])
      user.save(validate: false) && user
    end

    let(:child_1) do
      Child.create!(
        data: {
          status: 'open', worklow: 'open', sex: 'male', module_id: @module.unique_id,
          owned_by: case_worker_1.user_name
        }
      )
    end

    let(:child_2) do
      Child.create!(
        data: {
          status: 'open', worklow: 'open', sex: 'female', module_id: @module.unique_id,
          owned_by: case_worker_2.user_name
        }
      )
    end

    let(:child_3) do
      Child.create!(
        data: {
          status: 'open', worklow: 'open', sex: 'female', module_id: @module.unique_id,
          owned_by: case_worker_3.user_name
        }
      )
    end

    before(:each) do
      clean_data(User, UserGroup, Field, Lookup, Child, Report)
      Lookup.create!(
        unique_id: 'lookup-sex',
        name_en: 'sex',
        lookup_values_en: [
          { id: 'male', display_text: 'Male' },
          { id: 'female', display_text: 'Female' }
        ].map(&:with_indifferent_access)
      )

      Lookup.create!(
        unique_id: 'lookup-status',
        name_en: 'status',
        lookup_values_en: [
          { id: 'open', display_text: 'Open' },
          { id: 'closed', display_text: 'Closed' }
        ].map(&:with_indifferent_access)
      )

      Field.create!(
        name: 'sex', display_name: 'sex', type: Field::SELECT_BOX, option_strings_source: 'lookup lookup-sex'
      )

      Field.create!(
        name: 'status', display_name: 'status', type: Field::SELECT_BOX, option_strings_source: 'lookup lookup-status'
      )

      Field.create!(
        name: 'owned_by_groups',
        display_name: 'Groups of record owner',
        type: Field::SELECT_BOX,
        multi_select: true,
        option_strings_source: 'UserGroup'
      )

      child_1
      child_2
      child_3
    end

    let(:report) do
      Report.new(
        name: 'Report by Status and Sex',
        record_type: 'case',
        module_id: @module.unique_id,
        aggregate_by: ['status'],
        disaggregate_by: ['sex'],
        permission_filter: { 'attribute' => 'owned_by_groups', 'value' => [group_1.unique_id] }
      )
    end

    it 'can be seen by the group scope' do
      report.build_report
      expect(report.data).to eq(
        {
          'open' => { '_total' => 2, 'male' => { '_total' => 1 }, 'female' => { '_total' => 1 } },
          'closed' => { '_total' => 0 }
        }
      )
    end

    it 'can be seen by group if they also meet the filter' do
      report.filters = [{ 'attribute' => 'owned_by_groups', 'value' => [group_2.unique_id] }]
      report.build_report
      expect(report.data).to eq(
        {
          'open' => { '_total' => 1, 'male' => { '_total' => 0 }, 'female' => { '_total' => 1 } },
          'closed' => { '_total' => 0 }
        }
      )
    end
  end
end
