class Api::V2::IndicatorApiController < Api::V2::ChildrenController
  include Api::V2::Concerns::Pagination
  def index
    authorize! :read, model_class
    base_records =
      model_class.where("data->>'record_state' = ?", 'true')

    if params[:district].present?
  district = params[:district]

  base_records = base_records.where(
    "data->>'location_current' LIKE ?",
    "#{district}%"
  )
end  


if params[:'registration_date'].present?
  reg_date = params[:'registration_date']

  case reg_date
  when /^\d{4}-\d{1,2}-\d{1,2}$/ # YYYY-M-D or YYYY-MM-DD
    year, month, day = reg_date.split('-').map(&:to_i)

    date = Date.new(year, month, day) rescue nil
    return render json: { error: 'Invalid date' }, status: 400 unless date

    base_records = base_records.where(
      "(data->>'registration_date')::date = ?",
      date
    )

  when /^\d{4}-\d{1,2}$/ # YYYY-M or YYYY-MM
    year, month = reg_date.split('-').map(&:to_i)

    date = Date.new(year, month, 1) rescue nil
    return render json: { error: 'Invalid month' }, status: 400 unless date

    base_records = base_records.where(
      "(data->>'registration_date')::date BETWEEN ? AND ?",
      date.beginning_of_month,
      date.end_of_month
    )

  when /^\d{4}$/ # YYYY
    year = reg_date.to_i

    date = Date.new(year, 1, 1) rescue nil
    return render json: { error: 'Invalid year' }, status: 400 unless date

    base_records = base_records.where(
      "(data->>'registration_date')::date BETWEEN ? AND ?",
      date.beginning_of_year,
      date.end_of_year
    )
  end
end



    # Filter by case_id_display if provided
     if params[:case_id_display].present?
       base_records = base_records.where(
         "data->>'case_id_display' = ?",
         params[:case_id_display]
       )
     end
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
  union_council_38498c8
  assessment_requested_on
  assessment_due_date
  assessment_approved_date
  date_case_plan
  case_plan_due_date
  case_plan_approved_date
  date_closure
].freeze
  FIELD_RENAMES = {
  'union_council_38498c8' => 'union_council',
  'assessment_requested_on' => 'date_assessment_started',
  'assessment_due_date' => 'date_assessment_due',
  'date_case_plan' => 'date_case_plan_started',
  'case_plan_due_date' => 'date_case_plan_due_date',
  'date_closure' => 'date_case_closure'
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
      lookup-protection-concerns
      lookup-risk-level
      lookup-vulnerabilities-4cac6ec
      lookup-tehsil-vcnc-c056cc8
      lookup-gender
      lookup-case-closure-reason-d457423
     ].each do |uid|
      lookup = Lookup.find_by(unique_id: uid)
      next unless lookup
      @lookup_cache[uid] =
        lookup.lookup_values_i18n.each_with_object({}) do |v, h|
          h[v['id']] = v['display_text']['en']
        end
    end
  end
def map_case_plan_achieved!(data, record)
  updates = record.data['update_on_actions_taken_a4d549b']

  return data['case_plan_achieved'] = nil if updates.blank?

  statuses = updates.map { |u| u['the_status_of_that_need_ba8951e'] }.compact

  return data['case_plan_achieved'] = nil if statuses.empty?

  achieved_values = %w[
    fully_addressed_909f3ef
    partially_addressed_5e86f6c
  ]

  data['case_plan_achieved'] =
    statuses.any? { |s| achieved_values.include?(s) }
end
  def build_response(records)
    records.map do |record|
      data = record.data.slice(*selected_fields)
      map_lookups!(data)
      ensure_nullable_fields!(data)
      rename_fields!(data)
      map_owned_by_groups!(data)
      map_owner!(data)
      map_location!(data)
      map_case_plan_achieved!(data, record)
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
      protection_concerns
      vulnerabilities_57efd69
      owned_by
      registration_date
      record_state
      location_current
      vc_nc_0e00677
      risk_level
      primary_reason_for_closing_the_case_61b5529
      assessment_requested_on
      assessment_due_date
      assessment_approved_date
      date_case_plan
      case_plan_due_date
      case_plan_approved_date
      date_closure
    ]
  end
  def map_lookups!(data)
    data['sex'] =
      lookup('lookup-gender', data.delete('sex'))
    data['incidents'] =
      Array(data.delete('protection_concerns'))
        .map { |v| lookup('lookup-protection-concerns', v) }
    data['risk_level'] =
      lookup('lookup-risk-level', data.delete('risk_level'))
    data['case_closure_reason'] =
      lookup(
        'lookup-case-closure-reason-d457423',
        data.delete('primary_reason_for_closing_the_case_61b5529')
      )
    data['vulnerabilities'] =
      Array(data.delete('vulnerabilities_57efd69'))
        .map { |v| lookup('lookup-vulnerabilities-4cac6ec', v) }
    data['vc-nc'] =
      lookup(
        'lookup-tehsil-vcnc-c056cc8',
        data.delete('vc_nc_0e00677')
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
  # Top-level rename
  FIELD_RENAMES.each do |old_key, new_key|
    next unless data.key?(old_key)
    data[new_key] = data.delete(old_key)
  end
end
  def lookup(uid, value)
    return nil if value.blank?
    @lookup_cache.dig(uid, value) || value
  end
end
