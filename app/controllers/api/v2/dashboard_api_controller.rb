class Api::V2::DashboardApiController < Api::V2::ChildrenController
  include Api::V2::Concerns::Pagination

  def index
    authorize! :read, model_class
    
    # ---- Require case_id_display ----
    unless params[:case_id_display].present?
      return render json: { error: "case_id_display is required" }, status: :unprocessable_entity
    end

    base_records =
      model_class.where("data->>'record_state' = ?", 'true')

if params[:last_updated_at].present?
  date = Date.parse(params[:last_updated_at]) rescue nil

  if date
    base_records = base_records.where(
      "(data->>'last_updated_at')::timestamp >= ?",
      date.beginning_of_day
    )
  end
end
 
      # Filter by case_id_display if provided
    # if params[:case_id_display].present?
    #   base_records = base_records.where(
    #     "data->>'case_id_display' = ?",
    #     params[:case_id_display]
    #   )
    # end
    
    # Filter by case_id_display required
    base_records = base_records.where(
      "data->>'case_id_display' = ?",
      params[:case_id_display]
    )

    sort_column =
      model_class.column_names.include?(order_by) ? order_by : 'id'

    base_records = base_records.order(sort_column => order)

    total_count = base_records.count

    @records =
      pagination? ? base_records.offset(offset).limit(per) : base_records

    @metadata = {
      total: total_count,
      per: pagination? ? per : @records.size,
      page: pagination? ? page : 1
    }

    preload_supporting_data(@records)

    render json: {
      data: build_response(@records),
      metadata: @metadata
    }
  end

  private
  FAMILY_FIELDS = %w[
  relation
  relation_age
  relation_sex
  relation_name
  relation_is_alive
  occupation_4209ce4
  relation_telephone
  relation_is_caregiver
  relation_death_details
  does_the_family_member_have_identification__f783f54
  if_yes__specify_id_number_248fe69
  if_yes__specify_type_of_identification_f2c1ac8
  is_the_family_member_living_with_the_child__4535f6b
  is_the_caregiver_the_legal_guardian_of_the_child__1336748
].freeze

FAMILY_FIELD_RENAMES = {
  'occupation_4209ce4' => 'occupation',
  'does_the_family_member_have_identification__f783f54' => 'does_the_family_member_have_identification',
  'if_yes__specify_id_number_248fe69' => 'specify_id_number',
  'if_yes__specify_type_of_identification_f2c1ac8' => 'specify_type_of_identification',
  'is_the_family_member_living_with_the_child__4535f6b' => 'is_the_family_member_living_with_the_child',
  'is_the_caregiver_the_legal_guardian_of_the_child__1336748' => 'is_the_caregiver_the_legal_guardian_of_the_child'
}.freeze
  NULLABLE_FIELDS = %w[
  date_of_birth
  union_council_38498c8
  address_current
  child_s_permanent_address_5b70ebc
  how_can_the_child_be_contacted__if_not_directly__specify_through_whom_fd66020
  if_available__include_phone_number_6a5816a
  please_mark_the_age_of_the_main_caregiver_is_under_18__fde9ce3
  please_note_any_relevant_observations_on_the_household_characteristics_and_living_conditions_571837d
  assessment_requested_on
  tick_this_box_in_case_this_is_a_re_opened_case_which_was_closed_previously_78ff51a
  based_on_the_information_on_the_different_elements_stated_above__list_and_describe_the_different_risk_factors__including_safety_threats__incidents_ec3afa9
  based_on_the_information_on_the_different_elements_stated_above__list_and_describe_the_different_protective_factors__including_individual_strengths__care_and_support_available_to_the_child_10a00d8
  describe_the_views_and_wishes_of_the_child_regarding_their_needs__8bcd17c
  was_the_child_seen_individually_when_asking_about_their_situation__1e9cfab
  describe_the_views_and_wishes_of_the_parents__caregiver_or_trusted_adult__regarding_the_needs_of_the_child__0696162
  additional_notes_on_the_assessment__2a2bcc1
  describe_the_child_s_current_care_arrangement_4ec8a8c
  safety_da0a105
  family_8b06c06
  physical_health_963fa93
  tick_this_box_if_the_child_is_pregnant_50242ef
  emotional_wellbeing_fb91598
  details_6baabaa
  friends_and_social_network_1a18da1
  work_92d7152
  legal_situation_and_documentation_13832d2
  briefly_describe_the_child_s_situation_and_the_child_protection_risks_identified_at_the_time_of_registration_ee9cddf
  are_there_any_urgent_needs_that_require_an_immediate_response__within_24___48_hours__from_the_caseworker_and_or_other_service_providers__for_example_immediate_safety__safety_within_care_arrangement__urgent_mental_health_needs__physical__sexual_and_reproductive_health_needs__basic_needs_essential_for_survival__documentation__care_arrangement__etc___438ac1f
  if_yes__specify_urgent_needs_and_list_action_points_for_within_24h___48h_c35a662
  notes_on_how_and_by_whom_the_child_was_identified__optional__352e833
  define_and_list_smart_objectives_of_the_case_plan__consider_both_immediate_objectives_and_mid_term_or_long_term_objectives_0748481
  overview_of_actions_taken_as_part_of_the_case_plan_and_progress_made_towards_objectives_of_the_case_plan_a3bd650
  overview_of_the_child_s_current_situation_and_highlight_changes_in_comparison_to_date_initial_case_plan_was_drafted_dac446a
  is_it_required_for_another_assessment_to_be_carried_out___c671ca4
  if_yes__specify_what_changed_and_why_a_new_assessment_is_needed_edb95d6
  if_no__specify_the_reason_behind_your_decision_9c2ee42
  is_it_required_for_the_case_plan_to_be_adjusted__d178ce1
  if_yes__specify_what_changed_and_why_a_new_case_plan_is_needed_ac61b5a
  specify_the_reason_behind_your_decision_f47196a
  details_and_comments_on_next_steps_f28c688
].freeze

  FIELD_RENAMES = {
  'union_council_38498c8' => 'union_council',
   'address_current' => 'child_current_address',
  'child_s_permanent_address_5b70ebc' => 'child_permanent_address',
  'how_can_the_child_be_contacted__if_not_directly__specify_through_whom_fd66020' => 'how_to_contact_child',
  'if_available__include_phone_number_6a5816a' => 'available_phone_number',
  'size_of_the_household_d601f62' => 'size_of_the_household',
  'please_mark_the_age_of_the_main_caregiver_is_under_18__fde9ce3' => 'age_of_care_giver_is_under_18',
  'please_note_any_relevant_observations_on_the_household_characteristics_and_living_conditions_571837d' => 'observation_on_household_characteristics_and_living_conditions',
  'assessment_requested_on' => 'date_assessment_started',
  'tick_this_box_in_case_this_is_a_re_opened_case_which_was_closed_previously_78ff51a' => 'case_is_reopened',
  'based_on_the_information_on_the_different_elements_stated_above__list_and_describe_the_different_risk_factors__including_safety_threats__incidents_ec3afa9' => 'list_and_describe_risk_factors',
  'based_on_the_information_on_the_different_elements_stated_above__list_and_describe_the_different_protective_factors__including_individual_strengths__care_and_support_available_to_the_child_10a00d8' => 'list_and_describe_protective_factors',
  'describe_the_views_and_wishes_of_the_child_regarding_their_needs__8bcd17c' => 'views_and_wishes_of_the_child',
  'was_the_child_seen_individually_when_asking_about_their_situation__1e9cfab' => 'was_the_child_seen_individually_when_asking_about_their_situation',
  'describe_the_views_and_wishes_of_the_parents__caregiver_or_trusted_adult__regarding_the_needs_of_the_child__0696162' => 'views_and_wishes_of_parents_caregiver',
  'additional_notes_on_the_assessment__2a2bcc1' => 'additional_notes_on_the_assessment',
  'describe_the_child_s_current_care_arrangement_4ec8a8c' => 'describe_the_child_s_current_care_arrangement',
  'safety_da0a105' => 'child_safety_details',
  'family_8b06c06' => 'child_family_details',
  'physical_health_963fa93' => 'child_physical_health',
  'tick_this_box_if_the_child_is_pregnant_50242ef' => 'child_is_pregnant',
  'emotional_wellbeing_fb91598' => 'emotional_wellbeing_of_the_child',
  'details_6baabaa' => 'child_education_details',
  'friends_and_social_network_1a18da1' => 'child_friends_and_social_network',
  'work_92d7152' => 'child_work_details',
  'legal_situation_and_documentation_13832d2' => 'child_legal_situation_and_documentation',
  'briefly_describe_the_child_s_situation_and_the_child_protection_risks_identified_at_the_time_of_registration_ee9cddf' => 'child_protection_risks_identified_at_the_time_of_registration',
  'are_there_any_urgent_needs_that_require_an_immediate_response__within_24___48_hours__from_the_caseworker_and_or_other_service_providers__for_example_immediate_safety__safety_within_care_arrangement__urgent_mental_health_needs__physical__sexual_and_reproductive_health_needs__basic_needs_essential_for_survival__documentation__care_arrangement__etc___438ac1f' => 'child_needs_that_require_an_immediate_response',
  'if_yes__specify_urgent_needs_and_list_action_points_for_within_24h___48h_c35a662' => 'specify_urgent_needs_and_list_action_points_for_within_24h___48h',
  'notes_on_how_and_by_whom_the_child_was_identified__optional__352e833' => 'notes_on_how_and_by_whom_the_child_was_identified',
  'define_and_list_smart_objectives_of_the_case_plan__consider_both_immediate_objectives_and_mid_term_or_long_term_objectives_0748481' => 'define_and_list_smart_objectives_of_the_case_plan__consider_both_immediate_objectives_and_mid_term_or_long_term_objectives',
  'overview_of_actions_taken_as_part_of_the_case_plan_and_progress_made_towards_objectives_of_the_case_plan_a3bd650' => 'overview_of_actions_taken_as_part_of_the_case_plan_and_progress_made_towards_objectives_of_the_case_plan',
  'overview_of_the_child_s_current_situation_and_highlight_changes_in_comparison_to_date_initial_case_plan_was_drafted_dac446a' => 'overview_of_the_child_s_current_situation_and_highlight_changes_in_comparison_to_date_initial_case_plan_was_drafted',
  'is_it_required_for_another_assessment_to_be_carried_out___c671ca4' => 'is_it_required_for_another_assessment_to_be_carried_out',
  'if_yes__specify_what_changed_and_why_a_new_assessment_is_needed_edb95d6' => 'if_yes__specify_what_changed_and_why_a_new_assessment_is_needed',
  'if_no__specify_the_reason_behind_your_decision_9c2ee42' => 'if_no__specify_the_reason_behind_your_decision',
  'is_it_required_for_the_case_plan_to_be_adjusted__d178ce1' => 'is_it_required_for_the_case_plan_to_be_adjusted',
  'if_yes__specify_what_changed_and_why_a_new_case_plan_is_needed_ac61b5a' => 'if_yes__specify_what_changed_and_why_a_new_case_plan_is_needed',
  'specify_the_reason_behind_your_decision_f47196a' => 'specify_the_reason_behind_your_decision',
  'details_and_comments_on_next_steps_f28c688' => 'details_and_comments_on_next_steps'
}.freeze
NESTED_FIELD_RENAMES = {
  'size_of_the_household' => {
    'of_adults_284944' => 'no_of_adults',
    'of_children_140974' => 'no_of_children'
  }
}.freeze
  EXCLUDED_USER_GROUPS = %w[
  usergroup-primero-cp-families
  usergroup-primero-ftr
  usergroup-primero-cp
].freeze

  def preload_supporting_data(records)
    @user_map =
      User.where(user_name: records.map { |r| r.data['owned_by'] }.compact)
          .pluck(:user_name, :full_name)
          .to_h


  group_ids =
    records
      .flat_map { |r| Array(r.data['owned_by_groups']) }
      .compact
      .uniq
      .difference(EXCLUDED_USER_GROUPS)


  @user_group_map =
    UserGroup
      .where(unique_id: group_ids)
      .pluck(:unique_id, :name)
      .to_h


    @services_map =
      Transition
        .where(record_id: records.map(&:id))
        .where.not(service: [nil, ''])
        .order(:created_at)
        .group_by(&:record_id)

    location_codes =
      records.map { |r| r.data['location_current'] }.compact.uniq

    @location_map =
      Location.where(location_code: location_codes)
              .each_with_object({}) do |loc, h|
                h[loc.location_code] = loc.name_i18n['en']
              end

    preload_lookups
  end

  def preload_lookups
    @lookup_cache = {}

    %w[
      lookup-protection-concerns
      lookup-risk-level
      lookup-legal-and-displacement-status-801326f
      lookup-vulnerabilities-4cac6ec
      lookup-disability-type
      lookup-child-identified-a191671
      lookup-tehsil-vcnc-c056cc8
      lookup-service-type
      lookup-gender
      lookup-case-closure-reason-d457423
      lookup-new-care-arrangement-ed512eb
      lookup-birth-registration-a158f60
      lookup-country
      lookup-ethnicity
      lookup-religion
      lookup-language
      lookup-area-currently-living-c8aec0d
      lookup-type-of-household-b1476a8
      lookup-marital-status
      lookup-living-condition-527f603
      lookup-att1-5cde541
      lookup-att2-cc27a2b
      lookup-att3-fd84e99
      lookup-education-50a3e53
      lookup-review-case-plan-c2953be
      lookup-review-done-9b07499
    ].each do |uid|
      lookup = Lookup.find_by(unique_id: uid)
      next unless lookup

      @lookup_cache[uid] =
        lookup.lookup_values_i18n.each_with_object({}) do |v, h|
          h[v['id']] = v['display_text']['en']
        end
    end
  end

  def build_response(records)
    records.map do |record|
      data = record.data.slice(*selected_fields)


      map_lookups!(data)
      ensure_nullable_fields!(data)
      rename_fields!(data)
      normalize_family_details!(data)
      map_owned_by_groups!(data)
      map_owner!(data)
      map_services!(record.id, data)
      map_location!(data)

      { 'id' => record.id }.merge(data)
    end
  end

  def selected_fields
    @selected_fields ||= %w[
      case_id
      case_id_display
      owned_by_groups
      name
      sex
      age
      date_of_birth
      status
      how_was_the_child_identified_d17a651
      protection_concerns
      vulnerabilities_57efd69
      disability_status_d49c179
      owned_by
      registration_date
      record_state
      location_current
      vc_nc_0e00677
      risk_level
      service
      legal_and_displacement_status_1cf81c4
      primary_reason_for_closing_the_case_61b5529
      type_of_care_arrangement_17accd6
      birth_registration_16ac334
      nationality
      ethnicity
      religion
      language
      union_council_38498c8
      address_current
      child_s_permanent_address_5b70ebc
      area_currently_living_9cc4d2b
      how_can_the_child_be_contacted__if_not_directly__specify_through_whom_fd66020
      if_available__include_phone_number_6a5816a
      type_of_household_0966def
      size_of_the_household_d601f62
      please_mark_the_age_of_the_main_caregiver_is_under_18__fde9ce3
      maritial_status
      living_condition_4f6c390
      please_note_any_relevant_observations_on_the_household_characteristics_and_living_conditions_571837d
      family_details_section
      assessment_requested_on
      tick_this_box_in_case_this_is_a_re_opened_case_which_was_closed_previously_78ff51a
      perpetrator_identity_454f363
      if_the_perpetrator_is_known__mark_this_category_when_possible__4675970
      if_the_location_is_known__please_mark_the_categories_when_possible__4b296f0
      based_on_the_information_on_the_different_elements_stated_above__list_and_describe_the_different_risk_factors__including_safety_threats__incidents_ec3afa9
      based_on_the_information_on_the_different_elements_stated_above__list_and_describe_the_different_protective_factors__including_individual_strengths__care_and_support_available_to_the_child_10a00d8
      describe_the_views_and_wishes_of_the_child_regarding_their_needs__8bcd17c
      was_the_child_seen_individually_when_asking_about_their_situation__1e9cfab
      describe_the_views_and_wishes_of_the_parents__caregiver_or_trusted_adult__regarding_the_needs_of_the_child__0696162
      describe_the_child_s_current_care_arrangement_4ec8a8c
      safety_da0a105
      family_8b06c06
      physical_health_963fa93
      tick_this_box_if_the_child_is_pregnant_50242ef
      emotional_wellbeing_fb91598
      education_de4ef06
      details_6baabaa
      friends_and_social_network_1a18da1
      work_92d7152
      legal_situation_and_documentation_13832d2
      briefly_describe_the_child_s_situation_and_the_child_protection_risks_identified_at_the_time_of_registration_ee9cddf
      are_there_any_urgent_needs_that_require_an_immediate_response__within_24___48_hours__from_the_caseworker_and_or_other_service_providers__for_example_immediate_safety__safety_within_care_arrangement__urgent_mental_health_needs__physical__sexual_and_reproductive_health_needs__basic_needs_essential_for_survival__documentation__care_arrangement__etc___438ac1f
      if_yes__specify_urgent_needs_and_list_action_points_for_within_24h___48h_c35a662
      notes_on_how_and_by_whom_the_child_was_identified__optional__352e833
      define_and_list_smart_objectives_of_the_case_plan__consider_both_immediate_objectives_and_mid_term_or_long_term_objectives_0748481
      who_was_involved_in_reviewing_the_case_plan__fd958b7
      how_was_the_review_done_740fc00
      overview_of_actions_taken_as_part_of_the_case_plan_and_progress_made_towards_objectives_of_the_case_plan_a3bd650
      overview_of_the_child_s_current_situation_and_highlight_changes_in_comparison_to_date_initial_case_plan_was_drafted_dac446a
      is_it_required_for_another_assessment_to_be_carried_out___c671ca4
      if_yes__specify_what_changed_and_why_a_new_assessment_is_needed_edb95d6
      if_no__specify_the_reason_behind_your_decision_9c2ee42
      is_it_required_for_the_case_plan_to_be_adjusted__d178ce1
      if_yes__specify_what_changed_and_why_a_new_case_plan_is_needed_ac61b5a
      specify_the_reason_behind_your_decision_f47196a
      details_and_comments_on_next_steps_f28c688
      last_updated_at
    ]
  end

  def map_lookups!(data)
    data['sex'] =
      lookup('lookup-gender', data.delete('sex'))

    data['incidents'] =
      Array(data.delete('protection_concerns'))
        .map { |v| lookup('lookup-protection-concerns', v) }

    data['nationality'] =
      Array(data.delete('nationality'))
        .map { |v| lookup('lookup-country', v) }

    data['ethnicity'] =
      Array(data.delete('ethnicity'))
        .map { |v| lookup('lookup-ethnicity', v) }

    data['religion'] =
      Array(data.delete('religion'))
        .map { |v| lookup('lookup-religion', v) }

    data['language'] =
      Array(data.delete('language'))
        .map { |v| lookup('lookup-language', v) }

    data['risk_level'] =
      lookup('lookup-risk-level', data.delete('risk_level'))

    data['legal_displacement_status'] =
      lookup(
        'lookup-legal-and-displacement-status-801326f',
        data.delete('legal_and_displacement_status_1cf81c4')
      )

    data['birth_registration_status'] =
      lookup(
        'lookup-birth-registration-a158f60',
        data.delete('birth_registration_16ac334')
      )


    data['type_of_household'] =
      lookup(
        'lookup-type-of-household-b1476a8',
        data.delete('type_of_household_0966def')
      )

    data['case_closure_reason'] =
      lookup(
        'lookup-case-closure-reason-d457423',
        data.delete('primary_reason_for_closing_the_case_61b5529')
      )

    data['current_care_arrangement'] =
      lookup(
        'lookup-new-care-arrangement-ed512eb',
        data.delete('type_of_care_arrangement_17accd6')
      )

    data['who_was_involved_in_reviewing_the_case_plan'] =
      lookup(
        'lookup-review-case-plan-c2953be',
        data.delete('who_was_involved_in_reviewing_the_case_plan__fd958b7')
      )

    data['how_was_the_review_done'] =
      lookup(
        'lookup-review-done-9b07499',
        data.delete('how_was_the_review_done_740fc00')
      )

    data['vulnerabilities'] =
      Array(data.delete('vulnerabilities_57efd69'))
        .map { |v| lookup('lookup-vulnerabilities-4cac6ec', v) }

    data['disability'] =
      Array(data.delete('disability_status_d49c179'))
        .map { |v| lookup('lookup-disability-type', v) }

    data['source_of_information'] =
      lookup(
        'lookup-child-identified-a191671',
        data.delete('how_was_the_child_identified_d17a651')
      )

    data['child_living_condition'] =
      lookup(
        'lookup-living-condition-527f603',
        data.delete('living_condition_4f6c390')
      )

    data['child_maritial_status'] =
      lookup(
        'lookup-marital-status',
        data.delete('maritial_status')
      )

    data['area_of_living'] =
      lookup(
        'lookup-area-currently-living-c8aec0d',
        data.delete('area_currently_living_9cc4d2b')
      )

    data['vc-nc'] =
      lookup(
        'lookup-tehsil-vcnc-c056cc8',
        data.delete('vc_nc_0e00677')
      )

    data['perpetrator_identity'] =
      lookup(
        'lookup-att1-5cde541',
        data.delete('perpetrator_identity_454f363')
      )
    data['perpetrator_relation'] =
      lookup(
        'lookup-att2-cc27a2b',
        data.delete('if_the_perpetrator_is_known__mark_this_category_when_possible__4675970')
      )
    data['incident_location'] =
      lookup(
        'lookup-att3-fd84e99',
        data.delete('if_the_location_is_known__please_mark_the_categories_when_possible__4b296f0')
      )

    data['child_education'] =
      lookup(
        'lookup-education-50a3e53',
        data.delete('education_de4ef06')
      )

  end

  def map_owner!(data)
    return data['owned_by'] = nil if data['owned_by'].blank?
    data['owned_by_id'] = data['owned_by']
    data['owned_by'] = @user_map[data['owned_by']] || data['owned_by']
  end

  def map_owned_by_groups!(data)
  groups =
    Array(data['owned_by_groups']) - EXCLUDED_USER_GROUPS

  data['owned_by_groups'] =
    groups.map { |gid| @user_group_map[gid] || gid }
end

  def map_services!(record_id, data)
    services =
      Array(@services_map[record_id])
        .map(&:service)
        .map { |s| lookup('lookup-service-type', s) }

    data['services_provided'] = services
    data.delete('service')
  end

  def map_location!(data)
    data['location_code'] = data['location_current']
    code = data.delete('location_current')
    data['location'] = code ? (@location_map[code] || code) : nil
  end

 def ensure_nullable_fields!(data)
  NULLABLE_FIELDS.each do |field|
    data[field] = nil unless data.key?(field)
  end

  # Ensure nested keys exist
  NESTED_FIELD_RENAMES.each do |parent_key, mapping|
    next unless data[parent_key].is_a?(Hash)
    mapping.each do |_, new_nested|
      data[parent_key][new_nested] ||= nil
    end
  end
end
def rename_fields!(data)
  # Top-level rename
  FIELD_RENAMES.each do |old_key, new_key|
    next unless data.key?(old_key)

    data[new_key] = data.delete(old_key)
  end

  # Nested rename for known hash fields
  NESTED_FIELD_RENAMES.each do |parent_key, mapping|
    next unless data[parent_key].is_a?(Hash)

    mapping.each do |old_nested, new_nested|
      if data[parent_key].key?(old_nested)
        data[parent_key][new_nested] = data[parent_key].delete(old_nested)
      end
    end
  end
end


def normalize_family_details!(data)
  return unless data['family_details_section'].is_a?(Array)

  data['family_details_section'] = data['family_details_section'].map do |member|
    # Keep only allowed fields
    filtered = member.slice(*FAMILY_FIELDS)

    if filtered['relation_sex'].present?
      filtered['relation_sex'] =
        lookup('lookup-gender', filtered['relation_sex'])
    end

    # Rename fields
    FAMILY_FIELD_RENAMES.each do |old_key, new_key|
      filtered[new_key] = filtered.delete(old_key) if filtered.key?(old_key)
    end

    filtered
  end
end

  def lookup(uid, value)
    return nil if value.blank?
    @lookup_cache.dig(uid, value) || value
  end
end
