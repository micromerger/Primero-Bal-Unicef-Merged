class Api::V2::ChecklistApiController < Api::V2::ChildrenController
  include Api::V2::Concerns::Pagination
  def index
    authorize! :read, model_class
    base_records =
      model_class.where("data->>'record_state' = ?", 'true')

    # ---- Require case_id_display ----
    unless params[:case_id_display].present?
      return render json: { error: "case_id_display is required" }, status: :unprocessable_entity
    end  

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
  NULLABLE_FIELDS = %w[
  date_of_birth
  date_closure
  consent_for_services
  case_plan_approved
  signature_eeba911
  closure_approved
  has_the_case_closure_been_discussed_and_agreed_with_the_parents_or_caregivers__f72a606
  case_plan_approved
].freeze
  FIELD_RENAMES = {
  'date_closure' => 'date_case_closure',
  'consent_for_services' => 'consent_taken',
  'case_plan_approved' => 'case_plan_has_been_signed_off_by_the_child_protection_officer',
  'signature_eeba911' => 'caseworker_signature',
  'closure_approved' => 'closure_approved_by_cpo',
  'has_the_case_closure_been_discussed_and_agreed_with_the_parents_or_caregivers__f72a606' => 'case_closure_discussed_with_parents',
  'case_plan_approved' => 'case_plan_approved_by_cpo'
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
      lookup-gender
     ].each do |uid|
      lookup = Lookup.find_by(unique_id: uid)
      next unless lookup
      @lookup_cache[uid] =
        lookup.lookup_values_i18n.each_with_object({}) do |v, h|
          h[v['id']] = v['display_text']['en']
        end
    end
  end
  def map_referral_was_made!(data, record)
  updates = record.data['services_section']
  return data['referral_services_made_in_line_data_protection_principles'] = false if updates.blank?
  data['referral_services_made_in_line_data_protection_principles'] =
    updates.any? { |u| u['service_type'].present? }
end

def map_case_plan_collaborate!(data, record)
  updates = record.data['contact_subform_cf29365']
  return data['case_plan_collaboratively_developed_child_parents'] = false if updates.blank?
  data['case_plan_collaboratively_developed_child_parents'] =
    updates.any? { |u| u['unique_id'].present? }
end

  def build_response(records)
    records.map do |record|
      data = record.data.slice(*selected_fields)
      data["case_id_assigned"] = true
      data["case_eligible"] = true
      data["case_includes_initial_assessment_of_child_protection_risks"] =
        present_multi_select?(record.data['protection_concerns']) ||
        present_multi_select?(record.data['vulnerabilities_57efd69'])
      data["days_case_was_open_for"] =
      calculate_case_duration(
      record.data['registration_date'],
      record.data['date_closure']
      )
      data["reason_for_the_closure_is_clearly_documented"] =
      record.data['primary_reason_for_closing_the_case_61b5529'].present?  
  data["another_assessment_case_plan_was_required_implemented"] = [
  record.data['if_yes__specify_what_changed_and_why_a_new_assessment_is_needed_edb95d6'],
  record.data['if_yes__specify_what_changed_and_why_a_new_case_plan_is_needed_ac61b5a'],
  record.data['if_yes__specify_what_changed_and_why_a_new_assessment_is_needed_e82ffb6']
].any?(&:present?)
      data["review_of_case_plan_was_carried_out"] = [
  record.data['is_it_required_for_the_case_plan_to_be_adjusted__d178ce1']
].any? { |v| v.to_s == 'true' }
      map_lookups!(data)
      ensure_nullable_fields!(data)
      rename_fields!(data)
      map_owned_by_groups!(data)
      map_owner!(data)
      map_location!(data)
      map_referral_was_made!(data, record)
      map_case_plan_collaborate!(data, record)
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
      owned_by
      registration_date
      record_state
      location_current
      date_closure
      case_id_assigned
      case_eligible
      consent_for_services
      case_plan_approved
      signature_eeba911
      closure_approved
      has_the_case_closure_been_discussed_and_agreed_with_the_parents_or_caregivers__f72a606
      case_plan_approved
    ]
  end
  def map_lookups!(data)
    data['sex'] =
      lookup('lookup-gender', data.delete('sex'))
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
  def map_location!(data)
    data['location_code'] = data['location_current']
    code = data.delete('location_current')
    data['location'] = code ? (@location_map[code] || code) : nil
  end
 def ensure_nullable_fields!(data)
  NULLABLE_FIELDS.each do |field|
    data[field] = nil unless data.key?(field)
  end
end
def rename_fields!(data)
  FIELD_RENAMES.each do |old_key, new_key|
    next unless data.key?(old_key)
    data[new_key] = data.delete(old_key)
  end
end
def present_multi_select?(value)
  return false if value.blank?

  # handles JSON array or stringified array
  parsed =
    case value
    when String
      begin
        JSON.parse(value)
      rescue JSON::ParserError
        value
      end
    else
      value
    end

  parsed.is_a?(Array) && parsed.reject(&:blank?).any?
end

def calculate_case_duration(start_date, end_date)
  return nil if start_date.blank? || end_date.blank?

  begin
    start_d = Date.parse(start_date.to_s)
    end_d   = Date.parse(end_date.to_s)

    (end_d - start_d).to_i
  rescue ArgumentError
    nil
  end
end

  def lookup(uid, value)
    return nil if value.blank?
    @lookup_cache.dig(uid, value) || value
  end
end
