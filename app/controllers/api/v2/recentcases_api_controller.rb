class Api::V2::RecentcasesApiController < ActionController::API
  before_action :authenticate_with_token!
  include Api::V2::Concerns::Pagination

def index

  base_records =
    Child.find_by_sql(<<-SQL)
      SELECT *
      FROM (
        SELECT
          c.*,
          split_part(l.name_i18n->>'en', ':', 3) AS district,
          ROW_NUMBER() OVER (
            PARTITION BY split_part(l.name_i18n->>'en', ':', 3)
            ORDER BY (c.data->>'registration_date')::date DESC
          ) AS rn
        FROM cases c
        LEFT JOIN locations l
          ON c.data->>'location_current' = l.location_code
        WHERE c.data->>'record_state' = 'true'
      ) t
      WHERE rn = 1
      ORDER BY (t.data->>'registration_date')::date DESC
      LIMIT 3;
    SQL

    @records = base_records

    preload_supporting_data(@records)

    render json: { data: build_response(@records) }
  end

  private

  def authenticate_with_token!
    token_from_request = request.headers['token'] || params[:token]
    expected_token = ENV['API_TOKEN']

    unless token_from_request.present? && token_from_request == expected_token
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def preload_supporting_data(records)
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
      map_location!(data)

      { 'id' => record.id }.merge(data)
    end
  end

  def selected_fields
    %w[
      case_id
      case_id_display
      status
      protection_concerns
      vulnerabilities_57efd69
      registration_date
      location_current
      risk_level
      age
    ]
  end

  def map_lookups!(data)
    data['incidents'] =
      Array(data.delete('protection_concerns'))
        .map { |v| lookup('lookup-protection-concerns', v) }

    data['risk_level'] =
      lookup('lookup-risk-level', data.delete('risk_level'))

    data['vulnerabilities'] =
      Array(data.delete('vulnerabilities_57efd69'))
        .map { |v| lookup('lookup-vulnerabilities-4cac6ec', v) }
  end

  def map_location!(data)
    data['location_code'] = data['location_current']
    code = data.delete('location_current')

    location_name = code ? (@location_map[code] || code) : nil
    data['location'] = location_name

    if location_name
      parts = location_name.split(':')
      data['District'] = parts[2] if parts.length >= 3
    end
  end

  def lookup(uid, value)
    return nil if value.blank?
    @lookup_cache.dig(uid, value) || value
  end
end
