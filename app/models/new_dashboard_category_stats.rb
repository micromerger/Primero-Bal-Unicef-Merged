# frozen_string_literal: true

# Dedicated helper for NewDashboard category and field aggregations.
class NewDashboardCategoryStats
  AGE_GROUPS = ['0-5', '6-9', '10-13', '14-18', '18+', 'Unknown'].freeze

  def self.chart_data(scope_or_list)
    locations = NewDashboardLocationStats.location_names_map
    category_tallies(scope_or_list)
      .merge(demographic_tallies(scope_or_list, locations))
      .merge(culture_tallies(scope_or_list))
      .merge(age_tallies(scope_or_list))
      .merge(cases_per_workflow: NewDashboardWorkflowStats.chart_data(scope_or_list))
  end

  def self.category_tallies(scope_or_list)
    {
      cases_per_incidents: array_field_chart_data(scope_or_list, 'protection_concerns'),
      cases_per_vulnerabilities: array_field_chart_data(scope_or_list, 'vulnerabilities_aba2a7a'),
      cases_per_diagnosed_disability:
        tally_field(scope_or_list, 'does_the_child_have_any_of_the_following_disabilities__2a1788b'),
      cases_per_undiagnosed_disability: tally_field(scope_or_list, 'undiagnosed_disability_b164b9c'),
      cases_per_case_worker: case_worker_chart_data(scope_or_list)
    }
  end

  def self.demographic_tallies(scope_or_list, locations = nil)
    {
      cases_per_district: NewDashboardLocationStats.chart_data(scope_or_list, 2, locations),
      cases_per_tehsil: NewDashboardLocationStats.chart_data(scope_or_list, 3, locations),
      cases_per_incident_location: tally_field(scope_or_list, 'location_of_the_incident_1f10ef1'),
      cases_per_care_arrangement: tally_field(scope_or_list, 'current_care_arrangements_type'),
      cases_per_marital_status: tally_field(scope_or_list, 'maritial_status'),
      cases_per_nationality: tally_field(scope_or_list, 'nationality')
    }
  end

  def self.culture_tallies(scope_or_list)
    {
      cases_per_child_getting_education: tally_education(scope_or_list),
      cases_per_language: tally_field(scope_or_list, 'language'),
      cases_per_religion: tally_field(scope_or_list, 'religion')
    }
  end

  def self.tally_education(scope_or_list)
    counts = Hash.new(0)
    scope_or_list.each do |c|
      data = c.is_a?(Hash) ? c : c.data
      val = data['is_the_child_enrolled_in_formal_education__a512ab5']
      counts[val.to_s] += 1 unless val.nil? || val == ''
    end
    counts.sort_by { |_k, v| -v }.to_h
  end

  def self.tally_field(scope_or_list, field)
    counts = Hash.new(0)
    scope_or_list.each do |c|
      data = c.is_a?(Hash) ? c : c.data
      Array(data[field]).compact.reject(&:blank?).uniq.each { |v| counts[v] += 1 }
    end
    counts.sort_by { |_k, v| -v }.to_h
  end

  def self.array_field_chart_data(scope_or_list, field)
    counts = Hash.new { |h, k| h[k] = { open: 0, closed: 0 } }
    accumulate_field(scope_or_list, counts, field)
    counts.sort_by { |_k, v| -(v[:open] + v[:closed]) }.to_h
  end

  def self.accumulate_field(scope_or_list, counts, field)
    scope_or_list.each do |c|
      data = c.is_a?(Hash) ? c : c.data
      key = data['status'] == 'closed' ? :closed : :open
      Array(data[field]).compact.reject(&:blank?).uniq.each { |i| counts[i][key] += 1 }
    end
  end

  def self.case_worker_chart_data(scope_or_list)
    user_names = User.pluck(:user_name, :full_name).to_h
    counts = Hash.new { |h, k| h[k] = { label: user_names[k] || k.titleize, total: 0, open: 0, closed: 0 } }
    accumulate_case_workers(scope_or_list, counts)
    counts.sort_by { |_k, v| -v[:total] }.to_h
  end

  def self.accumulate_case_workers(scope_or_list, counts)
    scope_or_list.each do |c|
      data = c.is_a?(Hash) ? c : c.data
      user = data['owned_by']
      next if user.blank?

      key = data['status'] == 'closed' ? :closed : :open
      counts[user][:total] += 1
      counts[user][key] += 1
    end
  end

  def self.age_tallies(scope_or_list)
    { cases_per_age_groups: age_group_chart_data(scope_or_list) }
  end

  def self.age_group_chart_data(scope_or_list)
    counts = AGE_GROUPS.to_h { |g| [g, { open: 0, closed: 0 }] }
    accumulate_age_groups(scope_or_list, counts)
    counts
  end

  def self.accumulate_age_groups(scope_or_list, counts)
    scope_or_list.each do |c|
      data = c.is_a?(Hash) ? c : c.data
      group = determine_age_group(data['age'])
      key = data['status'] == 'closed' ? :closed : :open
      counts[group][key] += 1
    end
  end

  def self.determine_age_group(age)
    num = Integer(age, exception: false)
    return 'Unknown' if num.nil? || num.negative?

    case num
    when 0..5 then '0-5'
    when 6..9 then '6-9'
    when 10..13 then '10-13'
    when 14..18 then '14-18'
    else '18+'
    end
  end
end
