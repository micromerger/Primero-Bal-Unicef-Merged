class Api::V2::CaseidApiController < Api::V2::ChildrenController
  include Api::V2::Concerns::Pagination
  def index
    authorize! :read, model_class
    base_records =
      model_class.where("data->>'record_state' = ?", 'true')
if params[:district].blank?
  return render json: {
    error: 'district is required'
  }, status: :bad_request
end
district = params[:district]
base_records = base_records.where(
  "data->>'location_current' LIKE ?",
  "#{district}%"
)
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
    render json: {
      data: build_response(@records),
      metadata: @metadata
    }
  end
  def build_response(records)
    records.map do |record|
      data = record.data.slice(*selected_fields)
      { 'id' => record.id }.merge(data)
    end
  end
  def selected_fields
    @selected_fields ||= %w[
      case_id_display
    ]
  end
end
