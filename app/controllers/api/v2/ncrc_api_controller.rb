require 'set'
class Api::V2::NcrcApiController < ActionController::API
  before_action :authenticate_with_token!
  
  INCIDENTS_MAP = {
  "other" => "Child labour",
  "gbv_survivor" => "Missing child",
  "statelessness" => "Neglect"
}.freeze
 
DISABILITY_MAP = {
  "intellectual_impairment_fe32ad9" => "Intellectual Impairment",
  "invisible_impairments_3babc52"    => "Invisible Impairments",
  "mental_impairment_c0ce00a"        => "Mental Impairment",
  "physical_impairment_c13807c"      => "Physical Impairment",
  "sensory_impairment_668182a"       => "Sensory Impairment",
  "not_applicable_88989f1"           => "Not Applicable" # we will exclude this
}.freeze

EXCLUDED_DISABILITY_IDS = %w[
  not_applicable_88989f1
].freeze

  RISK_MAP = {
  "significant_harm_case_630afad" => "High",
  "regular_case_c64d92e" => "Medium",
  "not_eligible_for_case_management_564bddf" => "Low"
}.freeze

  def index
   
  month = params[:month]
  year  = params[:year]
  district = params[:district]
  
    unless month.to_i.between?(1, 12) && year.match?(/^\d{4}$/)
    return render json: {
      error: "Invalid month or year"
    }, status: :unprocessable_entity
    end

  filters = ["c.data->>'record_state' = 'true'"]

  if month.present?
  filters << ActiveRecord::Base.send(:sanitize_sql_array, [
    "to_char((c.data->>'registration_date')::date, 'MM') = ?", month.rjust(2, '0')
  ])
  end

  if year.present?
  filters << ActiveRecord::Base.send(:sanitize_sql_array, [
    "to_char((c.data->>'registration_date')::date, 'YYYY') = ?", year
  ])
  end

  if district.present?
  filters << ActiveRecord::Base.send(:sanitize_sql_array, [
    "c.data->>'location_current' LIKE ?", "%#{district}%"
  ])
  end

district_sql = <<~SQL
  SELECT
    l.name_i18n->>'en' AS district_full_name,
    c.data->>'case_status_reopened' AS case_status_reopened,
    c.data->>'sex' AS gender,
    c.data->>'age' AS age,
    c.data->>'status' AS status,
    c.data->'does_the_child_have_any_of_the_following_disabilities__2a1788b' AS disabilities,
    c.data->'does_the_child_belong_to_a_religious_minority__2fe579d' AS minority_status,
    c.data->'is_this_child_a_refugee__2866ddf' AS legal_id,
    c.data->'protection_concerns' AS incidents,
    c.data->'case_types_ex_a1dcf57' AS exploitation,
    c.data->'case_type_678847a' AS missing,
    c.data->'case_type_b1c70ad' AS neglect,
    c.data->'case_types_cb31d10' AS harmful,
    c.data->'case_type_43a3449' AS violence,
    c.data->>'nature_of_case_2e012f4' AS risk_level
  FROM cases c
  LEFT JOIN locations l
    ON c.data->>'location_current' = l.location_code
  WHERE #{filters.join(' AND ')}
SQL

district_rows = ActiveRecord::Base.connection.execute(district_sql)

lookups = {}
    %w[
      lookup-types-of-disability-c6ee01c
    ].each do |uid|
      lookup = Lookup.find_by(unique_id: uid)
      next unless lookup
      values = lookup.lookup_values_i18n
      values = JSON.parse(values) if values.is_a?(String)
      lookups[uid] = values.each_with_object({}) { |v, h| h[v['id']] = v['display_text']['en'] }
    end

    districts = {}

    district_rows.each do |row|

      full_name = row['district_full_name'] || ''
      district_name = full_name.split(':')[2] || 'N/A'
      district_name = 'N/A' if district_name.strip.empty?
      
      age_groups = {
       '0-5' => 0,
       '6-10' => 0,
       '11-15' => 0,
       '16-18' => 0,
       '18+' => 0,
       'N/A' => 0
      }

      districts[district_name] ||= {
        total_cases: 0,
        open_cases: 0,
        closed_cases: 0,
        reopened_cases: 0,
        gender: {},
        open_cases_gender: {},
        closed_cases_gender: {},
        age_group: age_groups.dup,
        open_cases_age_group: age_groups.dup,
        closed_cases_age_group: age_groups.dup,
        disability_status: { 'Yes' => 0, 'No' => 0 },
        disability_type: {},
        vulnerability_per_disability: {},
        minority_status: { 'Yes' => 0, 'No' => 0, 'N/A' => 0 },
        legal_status: {},
        incidents: {},
        incident_age_group: age_groups.dup,
        vulnerability: {},
        vulnerability_clustering: {
        "single_vulnerability" => 0,
        "two_vulnerability" => 0,
        "three_vulnerability" => 0,
        "three_plus_vulnerability" => 0
         },
        risk_level: {}
      }

      district = districts[district_name]

      district[:total_cases] += 1
      district[:open_cases] += 1 if row['status'] == 'open'
      district[:closed_cases] += 1 if row['status'] == 'closed'
      district[:reopened_cases] += 1 if row['case_status_reopened'] == 'true'
      district[:open_cases] = [district[:open_cases] - district[:reopened_cases], 0].max
      
raw_gender = row['gender']

      display =
  case raw_gender
  when 'male'
    'Male'
  when 'female'
    'Female'
  when nil, ''
    'N/A'
  else
    'Transgender'
  end

district[:gender][display] ||= 0
district[:gender][display] += 1

if row['status'] == 'open'
  district[:open_cases_gender][display] ||= 0
  district[:open_cases_gender][display] += 1
end

if row['status'] == 'closed'
  district[:closed_cases_gender][display] ||= 0
  district[:closed_cases_gender][display] += 1
end


      age =
  begin
    Integer(row['age'])
  rescue
    nil
  end

age_group =
  if age.nil?
    'N/A'
  else
    case age
    when 0..5 then '0-5'
    when 6..10 then '6-10'
    when 11..15 then '11-15'
    when 16..18 then '16-18'
    else '18+'
    end
  end
district[:age_group][age_group] += 1
if row['status'] == 'open'
  district[:open_cases_age_group][age_group] += 1
end
if row['status'] == 'closed'
  district[:closed_cases_age_group][age_group] += 1
end
      
case_vulns = Set.new
case_disability_types = []
district[:vulnerability] ||= {}
district[:vulnerability]["Child with disability"] ||= 0


if row['disabilities'].present?
  disabilities = JSON.parse(row['disabilities'])

  valid_disabilities = disabilities.reject do |dis_id|
    dis_id.blank? || EXCLUDED_DISABILITY_IDS.include?(dis_id)
  end

  if valid_disabilities.any?
    valid_disabilities.each do |dis_id|
      display = DISABILITY_MAP[dis_id] || dis_id.to_s.humanize

      # Count disability type
      district[:disability_type][display] ||= 0
      district[:disability_type][display] += 1

      case_disability_types << display

      # vulnerability per disability
      district[:vulnerability_per_disability][display] ||= {}
      case_vulns.each do |vuln|
        next if vuln == "Child with disability"
        district[:vulnerability_per_disability][display][vuln] ||= 0
        district[:vulnerability_per_disability][display][vuln] += 1
      end
    end

    district[:disability_status]['Yes'] += 1
    district[:vulnerability]["Child with disability"] += 1
    case_vulns.add("Child with disability")
  else
    district[:disability_status]['No'] += 1
  end
else
  district[:disability_status]['No'] += 1
end



minority_value = row['minority_status']
case minority_value
when 'true'
  district[:minority_status]['Yes'] += 1
when 'false'
  district[:minority_status]['No'] += 1
else
  district[:minority_status]['N/A'] += 1
end


refugee_value = row['legal_id']
if refugee_value == true || refugee_value.to_s == 'true'
  district[:legal_status]['Refugee'] ||= 0
  district[:legal_status]['Refugee'] += 1
end

if row['incidents'].present?
  incidents = JSON.parse(row['incidents'])
  incidents.each do |concern_id|
    # Only process if the incident is in the map
    next unless INCIDENTS_MAP.key?(concern_id)
    display = INCIDENTS_MAP[concern_id]
    district[:incidents][display] ||= 0
    district[:incidents][display] += 1
    # Update per age group
    district[:incident_age_group][age_group] ||= 0
    district[:incident_age_group][age_group] += 1
  end
end

# if row['incidents'].present?
#   JSON.parse(row['incidents']).each do |concern_id|
    
#     next unless INCIDENTS_MAP.key?(concern_id)
#     display = INCIDENTS_MAP[concern_id]
#     district[:incidents][display] ||= 0
#     district[:incidents][display] += 1
#   end
# end
vulnerability_labels = []
if row['exploitation'].present?
  exploitation_values = JSON.parse(row['exploitation'])
  if exploitation_values.include?("child_trafficking_fc0b2dd")
    district[:incidents]["Trafficking"] ||= 0
    district[:incidents]["Trafficking"] += 1
    district[:incident_age_group][age_group] += 1
  end
   if exploitation_values == ["child_trafficking_fc0b2dd"]
    if district[:incidents]["Child labour"].to_i > 0
      district[:incidents]["Child labour"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Child labour") if district[:incidents]["Child labour"] == 0
    end
  end
end


if row['missing'].present?
  missing_values = JSON.parse(row['missing'])
  if missing_values.include?("separated_a21152a")
    district[:vulnerability]["Separated child"] ||= 0
    district[:vulnerability]["Separated child"] += 1
    case_vulns.add("Separated child")
    vulnerability_labels << "Separated child"
  end
  if missing_values.include?("child_found_family_tracing_unaccompanied_d60bac4")
    district[:vulnerability]["Unaccompanied child"] ||= 0
    district[:vulnerability]["Unaccompanied child"] += 1
    case_vulns.add("Unaccompanied child")
    vulnerability_labels << "Unaccompanied child"
  end
  
  if missing_values == ["child_found_family_tracing_unaccompanied_d60bac4"]
    if district[:incidents]["Missing child"].to_i > 0
      district[:incidents]["Missing child"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Missing child") if district[:incidents]["Missing child"] == 0
    end
  end

  if missing_values == ["separated_a21152a"]
    if district[:incidents]["Missing child"].to_i > 0
      district[:incidents]["Missing child"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Missing child") if district[:incidents]["Missing child"] == 0
    end
  end

  if missing_values.sort == ["child_found_family_tracing_unaccompanied_d60bac4", "separated_a21152a"].sort
    if district[:incidents]["Missing child"].to_i > 0
      district[:incidents]["Missing child"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Missing child") if district[:incidents]["Missing child"] == 0
    end
  end

end


if row['neglect'].present?
  neglect_values = JSON.parse(row['neglect'])
  if neglect_values.include?("drug_abuses_0f36da1")
    district[:vulnerability]["Substance exposure"] ||= 0
    district[:vulnerability]["Substance exposure"] += 1
    case_vulns.add("Substance exposure")
    vulnerability_labels << "Substance exposure"
  end
  if neglect_values.include?("drug_abuses_0f36da1")
    district[:incidents]["Substance use"] ||= 0
    district[:incidents]["Substance use"] += 1
    district[:incident_age_group][age_group] += 1
  end

  if neglect_values.include?("residential_care_8c732e2")
    district[:vulnerability]["Institutional care"] ||= 0
    district[:vulnerability]["Institutional care"] += 1
    case_vulns.add("Institutional care")
    vulnerability_labels << "Institutional care"
  end
  
  if neglect_values == ["drug_abuses_0f36da1"]
    if district[:incidents]["Neglect"].to_i > 0
      district[:incidents]["Neglect"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Neglect") if district[:incidents]["Neglect"] == 0
    end
  end

  if neglect_values == ["residential_care_8c732e2"]
    if district[:incidents]["Neglect"].to_i > 0
      district[:incidents]["Neglect"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Neglect") if district[:incidents]["Neglect"] == 0
    end
  end

  if neglect_values.sort == ["residential_care_8c732e2", "drug_abuses_0f36da1"].sort
    if district[:incidents]["Neglect"].to_i > 0
      district[:incidents]["Neglect"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Neglect") if district[:incidents]["Neglect"] == 0
    end
  end

end

if row['harmful'].present?
  harmful_values = JSON.parse(row['harmful'])
  if harmful_values.include?("a_c8e3339")
    district[:incidents]["Child in conflict with law"] ||= 0
    district[:incidents]["Child in conflict with law"] += 1
    district[:incident_age_group][age_group] += 1
  end
  if harmful_values.include?("forced___early_child_marriage__546c6e7")
    district[:incidents]["Child marriage"] ||= 0
    district[:incidents]["Child marriage"] += 1
    district[:incident_age_group][age_group] += 1
  end
end


if row['violence'].present?
  violence_values = JSON.parse(row['violence'])
  if violence_values.include?("corporal_punishment_efd6e99")
    district[:incidents]["Physical violence"] ||= 0
    district[:incidents]["Physical violence"] += 1
    district[:incident_age_group][age_group] += 1
  end
  if violence_values.include?("emotional_abuse_e81d47f")
    district[:incidents]["Psychological abuse"] ||= 0
    district[:incidents]["Psychological abuse"] += 1
    district[:incident_age_group][age_group] += 1
  end

  if violence_values.include?("murder_8df7592")
    district[:incidents]["Physical violence"] ||= 0
    district[:incidents]["Physical violence"] += 1
    district[:incident_age_group][age_group] += 1
  end

   if violence_values.include?("physical_abuse___violence_0808ef6")
    district[:incidents]["Physical violence"] ||= 0
    district[:incidents]["Physical violence"] += 1
    district[:incident_age_group][age_group] += 1
  end

    if violence_values.include?("sexual_abuse___violence_70e4a88")
    district[:incidents]["Sexual abuse"] ||= 0
    district[:incidents]["Sexual abuse"] += 1
    district[:incident_age_group][age_group] += 1
  end
end

# vulnerability_labels << "Other" if vulnerability_labels.empty? # === ADD ===
      # -------- VULNERABILITY PER DISABILITY --------
      case_disability_types.each do |disability| # === ADD ===
        district[:vulnerability_per_disability][disability] ||= {}
        vulnerability_labels.each do |v|
          district[:vulnerability_per_disability][disability][v] ||= 0
          district[:vulnerability_per_disability][disability][v] += 1
        end
      end


case case_vulns.size
when 1
  district[:vulnerability_clustering]["single_vulnerability"] += 1
when 2
  district[:vulnerability_clustering]["two_vulnerability"] += 1
when 3
  district[:vulnerability_clustering]["three_vulnerability"] += 1
when 4..Float::INFINITY
  district[:vulnerability_clustering]["three_plus_vulnerability"] += 1
end

district[:risk_level] ||= {}
risk_id = row['risk_level']
next if risk_id.blank? || risk_id == 'null'
risk_id = risk_id.to_s.strip.downcase
display = RISK_MAP[risk_id]
next unless display   
district[:risk_level][display] ||= 0
district[:risk_level][display] += 1




    end

    per_page = params[:per].to_i > 0 ? params[:per].to_i : 10
    page     = params[:page].to_i > 0 ? params[:page].to_i : 1
    offset   = (page - 1) * per_page

    district_array = districts.to_a.sort_by { |name, _| name }

    total_districts = district_array.size
    total_pages = (total_districts.to_f / per_page).ceil

    paginated_districts = district_array.slice(offset, per_page) || []
    paginated_districts = paginated_districts.to_h
    
    month_label =
  if month.present? && year.present?
    "#{month.to_i.to_s.rjust(2, '0')}-#{year}"
  elsif year.present?
    year
  else
    "All"
  end

   render json: {
  meta: {
    page: page,
    per: per_page,
    total_districts: total_districts,
    total_pages: total_pages
  },
  cases: {
    month_label => paginated_districts
  }
}
  end
       
 private

 def authenticate_with_token!
   token_from_request = request.headers['token'] || params[:token]
   expected_token = ENV['API_TOKEN']

   unless token_from_request.present? && token_from_request == expected_token
     render json: { error: 'Unauthorized' }, status: :unauthorized
   end
 end
 end

  # private

  #  def authenticate_with_token!
  #    token = request.headers['token'] || params[:token]
  #    unless token.present? && token == 'abbas_mm'
  #      render json: { error: 'Unauthorized' }, status: :unauthorized
  #    end
  #  end

  # end