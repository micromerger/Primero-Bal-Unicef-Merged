class Api::V2::CmPortalController < ActionController::API
  before_action :authenticate_with_token!

  def index
    filters = ["c.data->>'record_state' = 'true'"]

  if params[:date_from].present? ^ params[:date_to].present?
    return render json: {
      error: "Both date_from and date_to are required."
    }, status: :unprocessable_entity
  end
  
   from_date = nil
  to_date = nil

  if params[:date_from].present? && params[:date_to].present?
    begin
      from_date = normalize_from_date(params[:date_from])
      to_date   = normalize_to_date(params[:date_to])
    rescue ArgumentError
      return render json: {
        error: "Invalid date format. Use YYYY, YYYY-M, YYYY-MM, or YYYY-MM-DD."
      }, status: :unprocessable_entity
    end

    if from_date > to_date
      return render json: {
        error: "date_from cannot be greater than date_to."
      }, status: :unprocessable_entity
    end
  end

if params[:date].present?
  date = params[:date]

  unless date.match?(/\A\d{4}(-\d{1,2})?(-\d{1,2})?\z/)
    return render json: {
      error: "Invalid date format. Use YYYY, YYYY-MM or YYYY-MM-DD."
    }, status: :unprocessable_entity
  end

  begin
    parts = date.split("-").map(&:to_i)

    case parts.length
    when 1
      Date.new(parts[0], 1, 1)

      filters << "EXTRACT(YEAR FROM (c.data->>'registration_date')::date) = #{parts[0]}"

    when 2
      Date.new(parts[0], parts[1], 1)

      filters << <<~SQL.squish
        EXTRACT(YEAR FROM (c.data->>'registration_date')::date) = #{parts[0]}
        AND EXTRACT(MONTH FROM (c.data->>'registration_date')::date) = #{parts[1]}
      SQL

    when 3
      Date.new(parts[0], parts[1], parts[2])

      filters << <<~SQL.squish
        EXTRACT(YEAR FROM (c.data->>'registration_date')::date) = #{parts[0]}
        AND EXTRACT(MONTH FROM (c.data->>'registration_date')::date) = #{parts[1]}
        AND EXTRACT(DAY FROM (c.data->>'registration_date')::date) = #{parts[2]}
      SQL
    end

  rescue ArgumentError
    return render json: {
      error: "Invalid date."
    }, status: :unprocessable_entity
  end
end

  if from_date && to_date
    filters << "(c.data->>'registration_date')::date BETWEEN '#{from_date}' AND '#{to_date}'"
  end



if params[:status].present?
  case params[:status].downcase
  when "open"
    filters << <<~SQL.squish
      c.data->>'status' = 'open'
      AND COALESCE(
        c.data->>'tick_this_box_in_case_this_is_a_re_opened_case_which_was_closed_previously_78ff51a',
        'false'
      ) != 'true'
    SQL

  when "closed"
    filters << "c.data->>'status' = 'closed'"

  when "reopened"
    filters << <<~SQL.squish
      c.data->>'status' = 'open'
      AND c.data->>'tick_this_box_in_case_this_is_a_re_opened_case_which_was_closed_previously_78ff51a' = 'true'
    SQL

  else
    return render json: {
      error: "Invalid status. Allowed values are open, closed, reopened."
    }, status: :unprocessable_entity
  end
end





# if params[:date_from].present?
#   from_date = normalize_from_date(params[:date_from])
#   filters << "(c.data->>'registration_date')::date >= '#{from_date}'"
# end

# if params[:date_to].present?
#   to_date = normalize_to_date(params[:date_to])
#   filters << "(c.data->>'registration_date')::date <= '#{to_date}'"
# end
    
sql = <<~SQL
  SELECT
    c.data->>'status' AS status,
    c.data->>'sex' AS gender,
    c.data->>'how_was_the_child_identified_d17a651' AS source_of_information,
    c.data->>'risk_level' AS risk_level,
    c.data->'services_section' AS services_section,
    c.data->>'registration_date' AS registration_date,
    c.data->'nationality' AS nationality,
    c.data->'protection_concerns' AS incidents,
    c.data->'vulnerabilities_57efd69' AS vulnerability,
    c.data->'disability_status_d49c179' AS disability,
    c.data->>'age' AS age,
    c.data->>'tick_this_box_in_case_this_is_a_re_opened_case_which_was_closed_previously_78ff51a'
      AS case_status_reopened,

    CASE
      WHEN array_length(string_to_array(l.name_i18n->>'en', ':'), 1) >= 3
      THEN split_part(l.name_i18n->>'en', ':', 3)
      ELSE NULL
    END AS district

  FROM cases c
  LEFT JOIN locations l
    ON c.data->>'location_current' = l.location_code

  WHERE #{filters.join(' AND ')}
SQL
  

    rows = ActiveRecord::Base.connection.execute(sql)

    summary = {
      total_cases: 0,
      open_cases: 0,
      closed_cases: 0,
      reopened_cases: 0
    }
     age_group_summary = {
  "0-5" => 0,
  "6-10" => 0,
  "11-15" => 0,
  "16-18" => 0,
  "18+" => 0,
  "Unknown" => 0
}
    


    gender_map, gender_summary = build_lookup_map("lookup-gender", include_unknown: true)
    source_map, source_summary = build_lookup_map("lookup-child-identified-a191671")
    risk_map, risk_summary = build_lookup_map("lookup-risk-level")
    service_map, service_summary = build_lookup_map("lookup-service-type")
    cases_per_year = Hash.new(0)
    district_summary = Hash.new(0)
    nationality_map, nationality_summary = build_lookup_map("lookup-country")
    incident_map, incident_summary = build_lookup_map("lookup-protection-concerns")
    vulnerability_map, vulnerability_summary = build_lookup_map("lookup-vulnerabilities-4cac6ec")
    disability_map, disability_summary = build_lookup_map("lookup-disability-type")
    
    rows.each do |row|
      summary[:total_cases] += 1

      if row["status"] == "open"
        if row["case_status_reopened"] == "true"
          summary[:reopened_cases] += 1
        else
          summary[:open_cases] += 1
        end
      elsif row["status"] == "closed"
        summary[:closed_cases] += 1
      end

      increment_lookup_count(row["gender"], gender_map, gender_summary, include_unknown: true)
      increment_lookup_count(row["source_of_information"], source_map, source_summary)
      increment_lookup_count(row["risk_level"], risk_map, risk_summary)
      services = row["services_section"]

if services.present?
  services = JSON.parse(services) if services.is_a?(String)

  services.each do |service|
    increment_lookup_count(
      service["service_type"],
      service_map,
      service_summary
    )
  end
end
      
      registration_date = row["registration_date"]

if registration_date.present?
  year = registration_date[0, 4] 
  cases_per_year[year] += 1
end

district = row["district"]

district_summary[district] += 1 if district.present?


nationalities = row["nationality"]

if nationalities.present?
  nationalities = JSON.parse(nationalities) if nationalities.is_a?(String)

  Array(nationalities).each do |nationality|
    increment_lookup_count(
      nationality,
      nationality_map,
      nationality_summary
    )
  end
end



incidents = row["incidents"]

if incidents.present?
  incidents = JSON.parse(incidents) if incidents.is_a?(String)

  Array(incidents).each do |incident|
    increment_lookup_count(
      incident,
      incident_map,
      incident_summary
    )
  end
end


vulnerability = row["vulnerability"]

if vulnerability.present?
  vulnerability = JSON.parse(vulnerability) if vulnerability.is_a?(String)

  Array(vulnerability).each do |vulnerability|
    increment_lookup_count(
      vulnerability,
      vulnerability_map,
      vulnerability_summary
    )
  end
end


disability = row["disability"]

if disability.present?
  disability = JSON.parse(disability) if disability.is_a?(String)

  Array(disability).each do |value|
    next if value == "no_disability_1df31de"

    increment_lookup_count(
      value,
      disability_map,
      disability_summary
    )
  end
end



age = row["age"]

if age.present?
  age = age.to_i

  case age
  when 0..5
    age_group_summary["0-5"] += 1
  when 6..10
    age_group_summary["6-10"] += 1
  when 11..15
    age_group_summary["11-15"] += 1
  when 16..18
    age_group_summary["16-18"] += 1
  else
    age_group_summary["18+"] += 1 if age > 18
  end
else
  age_group_summary["Unknown"] += 1
end



    end

    cases_per_year = cases_per_year.sort.reverse.to_h
   

    render json: {
      meta: {
        province: "KP"
      },
      KP: {
        cases_summary: summary,
        cases_per_gender: gender_summary,
        source_of_information: source_summary,
        cases_per_service_provided: service_summary,
        cases_per_year: cases_per_year,
        cases_per_district: district_summary,
        cases_per_nationality: nationality_summary,
        cases_per_age_groups: age_group_summary,
        cases_per_risk_level: risk_summary,
        cases_per_incidents: incident_summary,
        cases_per_vulnerabilities: vulnerability_summary,
        cases_per_disabilities: disability_summary    
      }
    }
  end

  private


def normalize_from_date(value)
  parts = value.split("-").map(&:to_i)

  case parts.length
  when 1
    Date.new(parts[0], 1, 1)
  when 2
    Date.new(parts[0], parts[1], 1)
  when 3
    Date.new(parts[0], parts[1], parts[2])
  else
    raise ArgumentError
  end
end

def normalize_to_date(value)
  parts = value.split("-").map(&:to_i)

  case parts.length
  when 1
    Date.new(parts[0], 12, 31)
  when 2
    Date.new(parts[0], parts[1], -1)
  when 3
    Date.new(parts[0], parts[1], parts[2])
  else
    raise ArgumentError
  end
end





def build_lookup_map(unique_id, include_unknown: false)
  lookup = Lookup.find_by(unique_id: unique_id)

  map = {}
  summary = {}

  if lookup.present?
    values = lookup.lookup_values_i18n
    values = JSON.parse(values) if values.is_a?(String)

    values.each do |value|
      map[value["id"]] = value["display_text"]["en"]
    end
  end

  summary["Unknown"] = 0 if include_unknown

  [map, summary]
end

def increment_lookup_count(value, map, summary, include_unknown: false)
  if value.present? && map.key?(value)
    key = map[value]
    summary[key] ||= 0
    summary[key] += 1
  elsif include_unknown
    summary["Unknown"] ||= 0
    summary["Unknown"] += 1
  end
end

#   def authenticate_with_token!
#     token = request.headers["token"] || params[:token]

#     unless token.present? && token == "abbas_mm"
#       render json: { error: "Unauthorized" }, status: :unauthorized
#     end
#   end
# end


    def authenticate_with_token!
      token_from_request = request.headers['token'] || params[:token]
      expected_token = ENV['CM_API'] # Read from environment

      unless token_from_request.present? && token_from_request == expected_token
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
    end