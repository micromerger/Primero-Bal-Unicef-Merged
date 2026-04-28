require 'set'
class Api::V2::NcrcApiController < ActionController::API
  before_action :authenticate_with_token!

INCIDENTS_MAP = {
  "gbv_survivor" => "Child labour",
  "statelessness" => "Psychological abuse",
  "trafficked_smuggled" => "Neglect",
  "other" => "Other",
  "arrested_detained" => "Physical violence",
  "sexually_exploited" => "Sexual abuse"
}.freeze

RISK_MAP = {
  "high" => "High",
  "medium" => "Medium",
  "low" => "Low"
}.freeze

NATIONALITY_MAP = {
  "afghani_797430" => "Afghanistan",
  "iran" => "Iran",
  "india" => "India",
  "china" => "China",
  "iraq" => "Iraq",
  "pakistani_883606" => "Pakistan",
  "usa" => "USA (United States of America)",
  "uk" => "UK (United Kingdom)",
  "palestine" => "Palestine"
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
    c.data->'nationality' AS nationality,
    c.data->'does_the_child_have_any_disability__e9b4262' AS disabilities,
    c.data->'does_the_child_belong_to_a_religious_minority__86d8304' AS minority_status,
    c.data->'child_is_a_refugee_03fc8c3' AS legal_id,
    c.data->'protection_concerns' AS incidents,
    c.data->'exploitation_cc3a73c' AS exploitation,
    c.data->'mental_violence_88f8d94' AS mental,
    c.data->'neglect_14bd24f' AS neglect,
    c.data->>'sexual_abuse_518f95a' AS sexual_abuse,
    c.data->>'status_of_child_when_found_2329f7b' AS status_child,
    c.data->>'risk_level' AS risk_level
  FROM cases c
  LEFT JOIN locations l
    ON c.data->>'location_current' = l.location_code
  WHERE #{filters.join(' AND ')}
SQL

district_rows = ActiveRecord::Base.connection.execute(district_sql)

lookups = {}
    %w[
      lookup-disability-type
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

#      district[:total_cases] += 1
#      district[:open_cases] += 1 if row['status'] == 'open'
#      district[:closed_cases] += 1 if row['status'] == 'closed'
#      district[:reopened_cases] += 1 if row['case_status_reopened'] == 'true'
#      district[:open_cases] = [district[:open_cases] - district[:reopened_cases], 0].max

district[:total_cases] += 1

if row['status'] == 'open'
  if row['case_status_reopened'] == 'true'
    district[:reopened_cases] += 1
  else
    district[:open_cases] += 1
  end
end

district[:closed_cases] += 1 if row['status'] == 'closed'

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
   valid_disabilities = disabilities.select { |dis_id| dis_id.present? && dis_id.to_s.strip != "" }
   if valid_disabilities.any?
     valid_disabilities.each do |dis_id|
       display = lookups['lookup-disability-type']&.dig(dis_id) || dis_id
       district[:disability_type][display] ||= 0
       district[:disability_type][display] += 1
       case_disability_types << display
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

if row['nationality'].present?
  JSON.parse(row['nationality']).each do |concern_id|
   display = NATIONALITY_MAP[concern_id] || "Other"
district[:nationality][display] ||= 0
district[:nationality][display] += 1
  end
end

if row['incidents'].present?
  incidents = JSON.parse(row['incidents'])
  incidents.each do |concern_id|
    display = INCIDENTS_MAP[concern_id] || concern_id
    district[:incidents][display] ||= 0
    district[:incidents][display] += 1

    # Update per age group
    district[:incident_age_group][age_group] ||= 0
    district[:incident_age_group][age_group] += 1
  end
end

# if row['incidents'].present?
 # JSON.parse(row['incidents']).each do |concern_id|
   # display = INCIDENTS_MAP[concern_id] || concern_id
   # district[:incidents][display] ||= 0
  #  district[:incidents][display] += 1
#  end
# end
vulnerability_labels = []

if row['exploitation'].present?
  exploitation_values = JSON.parse(row['exploitation'])
  allowed_for_child_labour = [
    "child_trafficking__within_and_between_countries__c680681",
    "child_labour___domestic_cee1f48"
  ]
  # --- Increment incidents ---
  if exploitation_values.include?("child_trafficking__within_and_between_countries__c680681")
    district[:incidents]["Trafficking"] ||= 0
    district[:incidents]["Trafficking"] += 1
    district[:incident_age_group][age_group] += 1
  end
  # --- Increment vulnerabilities ---
  if exploitation_values.include?("child_labour___domestic_cee1f48")
    district[:vulnerability]["Child domestic worker"] ||= 0
    district[:vulnerability]["Child domestic worker"] += 1
    case_vulns.add("Child domestic worker")
    vulnerability_labels << "Child domestic worker"
  end
  # --- Decrement Child labour ONLY if all values are in allowed list ---
  if exploitation_values.all? { |v| allowed_for_child_labour.include?(v) }
    if district[:incidents]["Child labour"].to_i > 0
      district[:incidents]["Child labour"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Child labour") if district[:incidents]["Child labour"] == 0
    end
  end
end

if row['mental'].present?
  mental_values = JSON.parse(row['mental'])
  allowed_for_psych_abuse = ["cybercrime_9651572"]
  # --- Increment incidents ---
  if mental_values.include?("cybercrime_9651572")
    district[:incidents]["Online abuse"] ||= 0
    district[:incidents]["Online abuse"] += 1
    district[:incident_age_group][age_group] += 1
  end
  # --- Decrement Psychological abuse ONLY if values are EXACTLY allowed ---
  if mental_values.all? { |v| allowed_for_psych_abuse.include?(v) }
    if district[:incidents]["Psychological abuse"].to_i > 0
      district[:incidents]["Psychological abuse"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Psychological abuse") if district[:incidents]["Psychological abuse"] == 0
    end
  end
end


if row['neglect'].present?
  neglect_values = JSON.parse(row['neglect'])
  allowed_for_neglect = ["exposure_to_drug_or_alcohol_abuse_d250c07"]
  # --- Increment incidents & vulnerabilities ---
  if neglect_values.include?("exposure_to_drug_or_alcohol_abuse_d250c07")
    district[:incidents]["Substance use"] ||= 0
    district[:incidents]["Substance use"] += 1
    district[:incident_age_group][age_group] += 1

    district[:vulnerability]["Substance exposure"] ||= 0
    district[:vulnerability]["Substance exposure"] += 1
    case_vulns.add("Substance exposure")
    vulnerability_labels << "Substance exposure"
  end
  # --- Decrement Neglect ONLY if values are EXACTLY allowed ---
  if neglect_values.all? { |v| allowed_for_neglect.include?(v) }
    if district[:incidents]["Neglect"].to_i > 0
      district[:incidents]["Neglect"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Neglect") if district[:incidents]["Neglect"] == 0
    end
  end
end


if row['sexual_abuse'].present?
  sexual_abuse_values = JSON.parse(row['sexual_abuse'])
  allowed_for_sexual_abuse = ["child_and_forced_marriage_1c99ee2"]
  # --- Increment incidents ---
  if sexual_abuse_values.include?("child_and_forced_marriage_1c99ee2")
    district[:incidents]["Child marriage"] ||= 0
    district[:incidents]["Child marriage"] += 1
    district[:incident_age_group][age_group] += 1
  end
  # --- Decrement Sexual abuse ONLY if array contains ONLY allowed values ---
  if sexual_abuse_values.all? { |v| allowed_for_sexual_abuse.include?(v) }
    if district[:incidents]["Sexual abuse"].to_i > 0
      district[:incidents]["Sexual abuse"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Sexual abuse") if district[:incidents]["Sexual abuse"] == 0
    end
  end
end


status_child = row['status_child']

case status_child
when "unaccompanied_317039"
  district[:vulnerability]["Unaccompanied child"] ||= 0
  district[:vulnerability]["Unaccompanied child"] += 1
  case_vulns.add("Unaccompanied child")
  vulnerability_labels << "Unaccompanied child"
when "separated_980669"
  district[:vulnerability]["Separated child"] ||= 0
  district[:vulnerability]["Separated child"] += 1
  case_vulns.add("Separated child")
  vulnerability_labels << "Separated child"
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
     token = request.headers['token'] || params[:token]
     unless token.present? && token == 'abbas_mm'
       render json: { error: 'Unauthorized' }, status: :unauthorized
     end
   end
 end

# private
#  def authenticate_with_token!
#    token_from_request = request.headers['token'] || params[:token]
#    expected_token = ENV['API_TOKEN']
#    unless token_from_request.present? && token_from_request == expected_token
#      render json: { error: 'Unauthorized' }, status: :unauthorized
#    end
#  end
#  end