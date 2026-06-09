class Api::V2::ClientApiController < Api::V2::ChildrenController
  include Api::V2::Concerns::Pagination

  def index
  authorize! :read, model_class

  if params[:district].blank?
    return render json: {
      error: 'district is required'
    }, status: :bad_request
  end

  district = params[:district]

base_records =
  model_class.where(
    "data->>'record_state' = ? AND data->>'status' = ?",
    'true',
    'closed'
  )

  # Apply district filter
  base_records = base_records.where(
    "data->>'location_current' LIKE ?",
    "#{district}%"
  )

     if params[:owned_by].present?
       base_records = base_records.where(
         "data->>'owned_by' = ?",
         params[:owned_by]
       )
     end


if params[:'date_closure'].present?
   close_date = params[:'date_closure']
  case close_date
  when /^\d{4}-\d{1,2}-\d{1,2}$/
    year, month, day = close_date.split('-').map(&:to_i)
    date = Date.new(year, month, day) rescue nil
    return render json: { error: 'Invalid date' }, status: 400 unless date
    base_records = base_records.where(
      "(data->>'date_closure')::date = ?",
      date
    )
  when /^\d{4}-\d{1,2}$/
    year, month = close_date.split('-').map(&:to_i)
    date = Date.new(year, month, 1) rescue nil
    return render json: { error: 'Invalid month' }, status: 400 unless date
    base_records = base_records.where(
      "(data->>'date_closure')::date BETWEEN ? AND ?",
      date.beginning_of_month,
      date.end_of_month
    )
  when /^\d{4}$/
    year = close_date.to_i
    date = Date.new(year, 1, 1) rescue nil
    return render json: { error: 'Invalid year' }, status: 400 unless date
    base_records = base_records.where(
      "(data->>'date_closure')::date BETWEEN ? AND ?",
      date.beginning_of_year,
      date.end_of_year
    )
  end
end

 
    if params[:'registration_date'].present?
  reg_date = params[:'registration_date']
  case reg_date
  when /^\d{4}-\d{1,2}-\d{1,2}$/
    year, month, day = reg_date.split('-').map(&:to_i)
    date = Date.new(year, month, day) rescue nil
    return render json: { error: 'Invalid date' }, status: 400 unless date
    base_records = base_records.where(
      "(data->>'registration_date')::date = ?",
      date
    )
  when /^\d{4}-\d{1,2}$/
    year, month = reg_date.split('-').map(&:to_i)
    date = Date.new(year, month, 1) rescue nil
    return render json: { error: 'Invalid month' }, status: 400 unless date
    base_records = base_records.where(
      "(data->>'registration_date')::date BETWEEN ? AND ?",
      date.beginning_of_month,
      date.end_of_month
    )
  when /^\d{4}$/
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

  def preload_supporting_data(records)
    @user_map =
      User.where(user_name: records.map { |r| r.data['owned_by'] }.compact)
          .pluck(:user_name, :full_name)
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
      lookup-gender
      lookup-risk-level
      lookup-vulnerabilities-4cac6ec
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

  def build_response(records)
    records.map do |record|
      data = record.data.slice(*selected_fields)
      map_lookups!(data)
      map_owner!(data)
      map_location!(data)
      { 'id' => record.id }.merge(data)
    end
  end

  def selected_fields
    @selected_fields ||= %w[
      case_id
      case_id_display
      name
      sex
      age
      status
      protection_concerns
      vulnerabilities_57efd69
      owned_by
      registration_date
      record_state
      location_current
      risk_level
      date_closure
      primary_reason_for_closing_the_case_61b5529
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


    data['vulnerabilities'] =
      Array(data.delete('vulnerabilities_57efd69'))
        .map { |v| lookup('lookup-vulnerabilities-4cac6ec', v) }
    
    data['case_closure_reason'] =
      lookup(
        'lookup-case-closure-reason-d457423',
        data.delete('primary_reason_for_closing_the_case_61b5529')
      )    

  end

  def map_owner!(data)
    return data['owned_by'] = nil if data['owned_by'].blank?
    data['owned_by_id'] = data['owned_by']
    data['owned_by'] = @user_map[data['owned_by']] || data['owned_by']
  end

  def map_location!(data)
    data['location_code'] = data['location_current']
    code = data.delete('location_current')
    data['location'] = code ? (@location_map[code] || code) : nil
  end
end
  def lookup(uid, value)
    return nil if value.blank?
    @lookup_cache.dig(uid, value) || value
  end
