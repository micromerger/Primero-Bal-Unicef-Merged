require 'set'
class Api::V2::NcrcApiController < ActionController::API
  before_action :authenticate_with_token!

  INCIDENTS_MAP = {
  "physical_violence_or_abuse_against_the_child" => "Physical violence",
  "psychological_violence_or_abuse_against_the_child" => "Psychological abuse",
  "neglect_of_the_child" => "Neglect",
  "sexual_violence_or_abuse_against_the_child" => "Sexual abuse",
  "child_in_conflict_with_the_law_or_detained" => "Child in conflict with the law",
  "child_labour" => "Child labour",
  "other" => "Other"
}.freeze

  VULNERBILITY_MAP = {
  "psychological_distress__moderate_to_severe__7d1adf5" => "Psychological distress",
  "child_marriage_932d87c" => "Child marriage",
  "separated_child_6bd237b" => "Separated child",
  "unaccompanied_child_12b0380" => "Unaccompanied child",
  "other_aa2ca9c" => "Other"
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
     error: "Invalid month or year",
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
    c.data->>'tick_this_box_in_case_this_is_a_re_opened_case_which_was_closed_previously_78ff51a' AS case_status_reopened,
    c.data->>'sex' AS gender,
    c.data->>'age' AS age,
    c.data->'protection_concerns' AS protection_concerns,
    c.data->'vulnerabilities_57efd69' AS vulnerabilities,
    c.data->'disability_status_d49c179' AS disabilities,
    c.data->>'status' AS status,
    c.data->>'religion' AS religion,
    c.data->>'legal_and_displacement_status_1cf81c4' AS legal_id,
    c.data->>'nationality' AS nationality,
    c.data->>'type_of_care_arrangement_17accd6' AS care_arrangement,
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
      lookup-religion
      lookup-legal-and-displacement-status-801326f
      lookup-country
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
        incidents: {},
        incident_age_group: age_groups.dup,
        vulnerability: {},
        vulnerability_clustering: {
  "single_vulnerability" => 0,
  "two_vulnerability" => 0,
  "three_vulnerability" => 0,
  "three_plus_vulnerability" => 0
},
        disability_status: { 'Yes' => 0, 'No' => 0 },
        disability_type: {},
        vulnerability_per_disability: {},
        minority_status: { 'Yes' => 0, 'No' => 0, 'N/A' => 0 },
        minority_type: {},
        legal_status: {},
        nationality: {},
        risk_level: {}
      }

      district = districts[district_name]

      district[:total_cases] += 1
      district[:open_cases] += 1 if row['status'] == 'open'
      district[:closed_cases] += 1 if row['status'] == 'closed'
      if row['case_status_reopened'].to_s == 'true'
         district[:reopened_cases] += 1
      end
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

case_vulns = Set.new

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
    end
  end
end

district[:vulnerability] ||= {}
district[:vulnerability]["Child with disability"] ||= 0
district[:vulnerability]["Displaced child"] ||= 0

if row['disabilities'].present?
  disabilities = JSON.parse(row['disabilities'])

  has_disability = false

  disabilities.each do |dis_id|
    display = lookups['lookup-disability-type']&.dig(dis_id) || 'N/A'

    # Only count if not "No disability"
    if display != 'No disability'
      district[:disability_type][display] ||= 0
      district[:disability_type][display] += 1
      has_disability = true
    end
  end

  # Set disability_status
  if has_disability
    district[:disability_status]['Yes'] += 1
     district[:vulnerability]["Child with disability"] += 1
case_vulns.add("Child with disability")
  else
    district[:disability_status]['No'] += 1
  end
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

legal_id = row['legal_id']
display  = lookups['lookup-legal-and-displacement-status-801326f']&.dig(legal_id)
allowed_statuses = ["Refugee", "Migrant"]
if allowed_statuses.include?(display)
  district[:legal_status][display] ||= 0
  district[:legal_status][display] += 1
end
if display == "Displaced"
  district[:vulnerability]["Displaced child"] ||= 0
  district[:vulnerability]["Displaced child"] += 1
case_vulns.add("Displaced child")
end

      if row['nationality'].present?
        JSON.parse(row['nationality']).each do |concern_id|
          next unless lookups['lookup-country']&.key?(concern_id)
          display = lookups['lookup-country'][concern_id]
          district[:nationality][display] ||= 0
          district[:nationality][display] += 1
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

      care_arrangement = row['care_arrangement']
      case care_arrangement
      when "child_in_institutional_or_residential_care__incl__orphanage__34da528"
        district[:vulnerability]["Institutional care"] ||= 0
        district[:vulnerability]["Institutional care"] += 1
        case_vulns.add("Institutional care")
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

# -------------------------------
# Vulnerability per Disability
# -------------------------------
if row['disabilities'].present? && case_vulns.any?

  disabilities = JSON.parse(row['disabilities'])

  disabilities.each do |dis_id|
    dis_display = lookups['lookup-disability-type']&.dig(dis_id)
    next if dis_display.blank? || dis_display == 'No disability'

    district[:vulnerability_per_disability][dis_display] ||= {}

    case_vulns.each do |vuln|
      next if vuln == "Child with disability"
      district[:vulnerability_per_disability][dis_display][vuln] ||= 0
      district[:vulnerability_per_disability][dis_display][vuln] += 1
    end
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
     
# private

# def authenticate_with_token!
#   token_from_request = request.headers['token'] || params[:token]
#   expected_token = ENV['API_TOKEN']

#   unless token_from_request.present? && token_from_request == expected_token
#     render json: { error: 'Unauthorized' }, status: :unauthorized
#   end
# end
# end



 private

  def authenticate_with_token!
    token = request.headers['token'] || params[:token]
    unless token.present? && token == 'abbas_mm'
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

 end