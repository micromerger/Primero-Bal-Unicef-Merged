require 'set'
class Api::V2::NcrcApiController < ActionController::API
  before_action :authenticate_with_token!

  INCIDENTS_MAP = {
  "sexually_exploited" => "Physical violence",
  "gbv_survivor" => "Psychological abuse",
  "trafficked_smuggled" => "Neglect",
  "arrested_detained" => "Sexual abuse",
  "statelessness" => "Child labour",
  "other" => "Other"
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
    c.data->>'case_status_reopened' AS case_status_reopened,
    c.data->>'sex' AS gender,
    c.data->>'age' AS age,
    c.data->>'status' AS status,
    c.data->'type_of_disability_1a238ec' AS disabilities,
    c.data->'does_the_child_belong_to_a_religious_minority__4f9ad5a' AS minority_status,
    c.data->'protection_concerns' AS protection_concerns,
    c.data->'emotional_mental_violence_dc53fad' AS mental,
    c.data->'neglect_or_negligent_treatment_7ce231d' AS neglect,
    c.data->'child_labour_exploitation_acd30ee' AS exploitation,
    c.data->>'sexual_abuse_and_exploitation_9d4fdc3' AS sexual_abuse
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

      # full_name = row['district_full_name'] || ''
      # district_name = full_name.split('::')[2] || 'ICT'
      # district_name = 'ICT' if district_name.strip.empty?

      # full_name = row['district_full_name'] || ''
      district_name = 'ICT'

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
        vulnerability: {},
        vulnerability_clustering: {
  "single_vulnerability" => 0,
  "two_vulnerability" => 0,
  "three_vulnerability" => 0,
  "three_plus_vulnerability" => 0
},
        minority_status: { 'Yes' => 0, 'No' => 0, 'N/A' => 0 },
        incidents: {},
        incident_age_group: age_groups.dup
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
case_vulns = Set.new
vulnerability_labels = []
case_disability_types = []
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

if row['mental'].present?
  mental_values = JSON.parse(row['mental'])
  if mental_values.include?("cybercrime_c118e68")
    district[:incidents]["Online abuse"] ||= 0
    district[:incidents]["Online abuse"] += 1
    district[:incident_age_group][age_group] += 1
  end
  if mental_values == ["cybercrime_c118e68"]
    if district[:incidents]["Psychological abuse"].to_i > 0
      district[:incidents]["Psychological abuse"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Psychological abuse") if district[:incidents]["Psychological abuse"] == 0
    end
  end
end


district[:vulnerability] ||= {}
district[:vulnerability]["Child with disability"] ||= 0
district[:vulnerability]["Substance exposure"] ||= 0

if row['neglect'].present?
  neglect_values = JSON.parse(row['neglect'])
  if neglect_values.include?("exposure_to_drug_and_or_alcohol_abuse_ce7c10a")
    district[:incidents]["Substance use"] ||= 0
    district[:incidents]["Substance use"] += 1
    district[:incident_age_group][age_group] += 1

    district[:vulnerability]["Substance exposure"] ||= 0
    district[:vulnerability]["Substance exposure"] += 1
    vulnerability_labels << "Substance exposure"
    case_vulns.add("Substance exposure")
  end

  if neglect_values == ["exposure_to_drug_and_or_alcohol_abuse_ce7c10a"]
    if district[:incidents]["Neglect"].to_i > 0
      district[:incidents]["Neglect"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Neglect") if district[:incidents]["Neglect"] == 0
    end
  end
end

if row['exploitation'].present?
  exploitation_values = JSON.parse(row['exploitation'])

  trafficking_keys = [
    "child_trafficking_for_forced_labour_07f388e",
    "child_trafficking_for_slavery_38875a0"
  ]

  domestic_key = "child_labour___domestic_labour_6a2f34a"

  allowed_keys = trafficking_keys + [domestic_key]

  # ---------- Trafficking ----------
  if (exploitation_values & trafficking_keys).any?
    district[:incidents]["Trafficking"] ||= 0
    district[:incidents]["Trafficking"] += 1
    district[:incident_age_group][age_group] += 1
  end

  # ---------- Domestic ----------
  if exploitation_values.include?(domestic_key)
    district[:vulnerability]["Child domestic worker"] ||= 0
    district[:vulnerability]["Child domestic worker"] += 1
    vulnerability_labels << "Child domestic worker"
    case_vulns.add("Child domestic worker")
  end

  # ---------- Remove Child labour ONLY if no other value exists ----------
  only_allowed_present = (exploitation_values - allowed_keys).empty?

  if only_allowed_present
    if district[:incidents]["Child labour"].to_i > 0
      district[:incidents]["Child labour"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Child labour") if district[:incidents]["Child labour"] == 0
    end
  end
end

if row['sexual_abuse'].present?
  sexual_abuse_values = JSON.parse(row['sexual_abuse'])

  if sexual_abuse_values.include?("child_and_forced_marriages_c8ec4a0")
    district[:incidents]["Child marriage"] ||= 0
    district[:incidents]["Child marriage"] += 1
    district[:incident_age_group][age_group] += 1
  end

    if sexual_abuse_values == ["child_and_forced_marriages_c8ec4a0"]
    if district[:incidents]["Sexual abuse"].to_i > 0
      district[:incidents]["Sexual abuse"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Sexual abuse") if district[:incidents]["Sexual abuse"] == 0
    end
  end


  if sexual_abuse_values.include?("child_trafficking__sexual_exploitation__3a0d72e")
    district[:incidents]["Trafficking"] ||= 0
    district[:incidents]["Trafficking"] += 1
    district[:incident_age_group][age_group] += 1
  end

  if sexual_abuse_values == ["child_trafficking__sexual_exploitation__3a0d72e"]
    if district[:incidents]["Sexual abuse"].to_i > 0
      district[:incidents]["Sexual abuse"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Sexual abuse") if district[:incidents]["Sexual abuse"] == 0
    end
  end

      if sexual_abuse_values.sort == ["child_trafficking__sexual_exploitation__3a0d72e", "child_and_forced_marriages_c8ec4a0"].sort
    if district[:incidents]["Sexual abuse"].to_i > 0
      district[:incidents]["Sexual abuse"] -= 1
      district[:incident_age_group][age_group] -= 1
      district[:incidents].delete("Sexual abuse") if district[:incidents]["Sexual abuse"] == 0
    end
  end

end

if row['disabilities'].present?
  disabilities = JSON.parse(row['disabilities'])
  has_disability = false
  disabilities.each do |dis_id|
    display = lookups['lookup-disability-type']&.dig(dis_id) || 'N/A'
    if display != 'No disability'
      district[:disability_type][display] ||= 0
      district[:disability_type][display] += 1
      case_disability_types << display
      has_disability = true
    end
  end
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


minority_value = row['minority_status']
case minority_value
when 'true'
  district[:minority_status]['Yes'] += 1
when 'false'
  district[:minority_status]['No'] += 1
else
  district[:minority_status]['N/A'] += 1
end



      case_disability_types.each do |disability|
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

#     private

#   def authenticate_with_token!
#     token = request.headers['token'] || params[:token]
#     unless token.present? && token == 'abbas_mm'
#       render json: { error: 'Unauthorized' }, status: :unauthorized
#     end
#   end

# end

  private

  def authenticate_with_token!
    token_from_request = request.headers['token'] || params[:token]
    expected_token = ENV['API_TOKEN'] # Read from environment

    unless token_from_request.present? && token_from_request == expected_token
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
  end