require 'set'
class Api::V2::NcrcApiController < ActionController::API
  before_action :authenticate_with_token!

  NATIONALITY_MAP = {
  "afghan_national_e97b3dd" => "Afghanistan",
  "national_0ea5a20" => "Pakistan",
  "stateless_6498790" => "Stateless",
  "unknown_90825cf" => "Unknown",
  "other_abec6a9" => "Other"
}.freeze

  INCIDENTS_MAP = {
  "arrested_detained" => "Physical violence",
  "psychological_violence_30bd37a" => "Psychological abuse",
  "statelessness" => "Neglect",
  "sexual_exploitation_c6951a2" => "Sexual abuse",
  "trafficked_smuggled" => "Child in conflict with the law",
  "other" => "Child labour",
  "abuse_ce5ab7f" => "Other"
}.freeze

  VULNERBILITY_MAP = {
  "psychological_distress__moderate_to_severe__890a3e9" => "Psychological distress",
  "child_marriage_7341353" => "Child marriage",
  "separated_child_4b5f58a" => "Separated child",
  "unaccompanied_child_7b895fa" => "Unaccompanied child",
  "other_e0fe579" => "Other"
}.freeze

  DISABILITY_MAP = {
  "intellectual_impairment_fe32ad9" => "Intellectual impairments",
  "mental_impairment_c0ce00a" => "Mental impairments",
  "physical_impairment_c13807c" => "Physical impairments",
  "sensory_impairment_668182a" => "Sensory impairments",
  "visual_2aa6e3d" => "Invisible impairments",
  "hearing_3fe7ad1" => "Hearing impairments"
}.freeze

  UN_DISABILITY_MAP = {
  "visual__829b11d" => "Invisible impairments",
  "hearing_b5fdc7a" => "Hearing impairments",
  "mobility_dbee5df" => "Physical impairments",
  "communication_bd51f9f" => "Communication impairments",
  "comprehension_89a5d44" => "Comprehension impairments",
  "behaviour_and_learning_19a6438" => "Developmental or Learning",
  "dexterity_and_playing__2_4_years__dbd9a74" => "Dexterity and playing (2-4 years)",
  "self_care__remembering__focusing_attention__coping_with_change__relationships_and_emotions__5_17_years__a078f43" => "Self-care, remembering, focusing attention, coping with change, relationships and emotions (5-17 years)"
}.freeze

RISK_MAP = {
  "high" => "High",
  "medium" => "Medium",
  "low" => "Low"
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
    c.data->>'religion' AS religion,
    c.data->>'does_the_child_have_a_disability__f451011' AS disability_status,
    c.data->'nationality' AS nationality,
    c.data->'protection_concerns' AS protection_concerns,
    c.data->'vulnerabilities_aba2a7a' AS vulnerabilities,
    c.data->>'is_the_child_s_family_displaced__6950113' AS displaced,
    c.data->>'current_care_arrangements_type' AS care_arrangement,
    c.data->'does_the_child_have_any_of_the_following_disabilities__2a1788b' AS disability_type,
    c.data->'undiagnosed_disability_b164b9c' AS un_disability_type,
    c.data->>'risk_level' AS risk_level
  FROM cases c
  LEFT JOIN locations l
    ON c.data->>'location_current' = l.location_code
  WHERE #{filters.join(' AND ')}
SQL

district_rows = ActiveRecord::Base.connection.execute(district_sql)

lookups = {}
    %w[
      lookup-religion
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
        minority_type: {},
        nationality: {},
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
      district[:reopened_cases] += 1 if row['case_status_reopened'] == 'true' && row['status'] == 'open'
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

district[:vulnerability] ||= {}
district[:vulnerability]["Child with disability"] ||= 0
# Initialize counters if not already
district[:disability_status] ||= { 'Yes' => 0, 'No' => 0 }
# Get the value from the row
disability_value = row['disability_status'].to_s.downcase.strip
# Increment Yes if it matches either of the 'yes' codes
if ["yes___officially_diagnosed__a17339c", "yes___undiagnosed_disability_f1bcd96"].include?(disability_value)
  district[:disability_status]['Yes'] += 1
  district[:vulnerability]["Child with disability"] += 1
  case_vulns.add("Child with disability")
else
  district[:disability_status]['No'] += 1
end


if row['religion'].present?
  religions = JSON.parse(row['religion'])
  has_minority = false
  all_islam = true

  religions.each do |religion_id|
    display = lookups['lookup-religion']&.dig(religion_id) || 'N/A'

    if display != 'Islam' && display != 'N/A'
      district[:minority_type][display] ||= 0
      district[:minority_type][display] += 1
      has_minority = true
      all_islam = false
    elsif display == 'Islam'
      all_islam &&= true
    end
  end

  if has_minority
    district[:minority_status]['Yes'] += 1
  elsif all_islam
    district[:minority_status]['No'] += 1
  else
    district[:minority_status]['N/A'] += 1
  end
else
  district[:minority_status]['N/A'] += 1
end

if row['nationality'].present?
  JSON.parse(row['nationality']).each do |concern_id|
   display = NATIONALITY_MAP[concern_id] || "Other"
   district[:nationality][display] ||= 0
   district[:nationality][display] += 1
  end
end

if row['protection_concerns'].present?
 incidents = JSON.parse(row['protection_concerns'])
 incidents.each do |concern_id|
    display = INCIDENTS_MAP[concern_id] || concern_id
    district[:incidents][display] ||= 0
    district[:incidents][display] += 1
  end
    district[:incident_age_group][age_group] ||= 0
  district[:incident_age_group][age_group] += incidents.size
end
row_vulnerabilities = Set.new
if row['vulnerabilities'].present?
  JSON.parse(row['vulnerabilities']).each do |vuln_id|
    display = VULNERBILITY_MAP[vuln_id] || vuln_id
    # Move "Child marriage" to incidents instead of vulnerability
    if display == "Child marriage"
      district[:incidents][display] ||= 0
      district[:incidents][display] += 1
      district[:incident_age_group][age_group] += 1
    else
      district[:vulnerability][display] ||= 0
      district[:vulnerability][display] += 1
      case_vulns.add(display)
      row_vulnerabilities.add(display)
    end
  end
end

if row['displaced'].to_s == 'true'
  district[:vulnerability]["Displaced child"] ||= 0
  district[:vulnerability]["Displaced child"] += 1
  case_vulns.add("Displaced child")
  row_vulnerabilities.add("Displaced child")
end

 care_arrangement = row['care_arrangement']
 case care_arrangement
 when "foster_care"
        district[:vulnerability]["Institutional care"] ||= 0
        district[:vulnerability]["Institutional care"] += 1
        case_vulns.add("Institutional care")
        row_vulnerabilities.add("Institutional care")
 end

district[:disability_type] ||= {}

# collect disabilities for THIS ROW only
row_disabilities = Set.new
# 1️⃣ Diagnosed disabilities
if row['disability_type'].present?
  JSON.parse(row['disability_type']).each do |concern_id|
    display = DISABILITY_MAP[concern_id]
    row_disabilities.add(display) if display.present?
  end
end
# 2️⃣ Undiagnosed disabilities
if row['un_disability_type'].present?
  JSON.parse(row['un_disability_type']).each do |concern_id|
    display = UN_DISABILITY_MAP[concern_id]
    row_disabilities.add(display) if display.present?
  end
end
# 3️⃣ Increment ONCE per disability per case
row_disabilities.each do |display|
  district[:disability_type][display] ||= 0
  district[:disability_type][display] += 1
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


district[:vulnerability_per_disability] ||= {}
row_disabilities.each do |disability|
  district[:vulnerability_per_disability][disability] ||= {}
  row_vulnerabilities.each do |vulnerability|
    district[:vulnerability_per_disability][disability][vulnerability] ||= 0
    district[:vulnerability_per_disability][disability][vulnerability] += 1
  end
end


risk_id = row['risk_level']
if risk_id.present? && risk_id != 'null'
  risk_id = risk_id.to_s.strip.downcase
  display = RISK_MAP[risk_id]

  if display
    district[:risk_level][display] ||= 0
    district[:risk_level][display] += 1
  end
end

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
  expected_token = ENV['API_TOKEN'] # Read from environment

  unless token_from_request.present? && token_from_request == expected_token
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
end

