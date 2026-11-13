# frozen_string_literal: true

# Dedicated helper for NewDashboard category and field aggregations.
class NewDashboardCategoryStats
  AGE_GROUPS = ['0-5', '6-9', '10-13', '14-18', '18+', 'Unknown'].freeze

  def self.chart_data(scope)
    category_tallies(scope)
      .merge(demographic_tallies(scope))
      .merge(culture_tallies(scope))
      .merge(age_tallies(scope))
      .merge(cases_per_workflow: NewDashboardWorkflowStats.chart_data(scope))
  end

  def self.category_tallies(scope)
    {
      cases_per_incidents: array_field_chart_data(scope, 'protection_concerns'),
      cases_per_vulnerabilities: array_field_chart_data(scope, 'vulnerabilities_aba2a7a'),
      cases_per_diagnosed_disability:
        tally_field(scope, 'does_the_child_have_any_of_the_following_disabilities__2a1788b'),
      cases_per_undiagnosed_disability: tally_field(scope, 'undiagnosed_disability_b164b9c'),
      cases_per_case_worker: case_worker_chart_data(scope)
    }
  end

  def self.demographic_tallies(scope)
    {
      cases_per_district: NewDashboardLocationStats.chart_data(scope, 2),
      cases_per_tehsil: NewDashboardLocationStats.chart_data(scope, 3),
      cases_per_incident_location: tally_field(scope, 'location_of_the_incident_1f10ef1'),
      cases_per_care_arrangement: tally_field(scope, 'current_care_arrangements_type'),
      cases_per_marital_status: tally_field(scope, 'maritial_status'),
      cases_per_nationality: tally_field(scope, 'nationality')
    }
  end

  def self.culture_tallies(scope)
    {
      cases_per_child_getting_education: tally_education(scope),
      cases_per_language: tally_field(scope, 'language'),
      cases_per_religion: tally_field(scope, 'religion')
    }
  end

  def self.tally_education(scope)
    counts = Hash.new(0)
    scope.each do |c|
      val = c.data['is_the_child_enrolled_in_formal_education__a512ab5']
      counts[val.to_s] += 1 unless val.nil? || val == ''
    end
    counts.sort_by { |_k, v| -v }.to_h
  end

  def self.tally_field(scope, field)
    counts = Hash.new(0)
    scope.each do |c|
      Array(c.data[field]).compact.reject(&:blank?).uniq.each { |v| counts[v] += 1 }
    end
    counts.sort_by { |_k, v| -v }.to_h
  end

  def self.array_field_chart_data(scope, field)
    counts = Hash.new { |h, k| h[k] = { open: 0, closed: 0 } }
    accumulate_field(scope, counts, field)
    counts.sort_by { |_k, v| -(v[:open] + v[:closed]) }.to_h
  end

  def self.accumulate_field(scope, counts, field)
    scope.each do |c|
      key = c.data['status'] == 'closed' ? :closed : :open
      Array(c.data[field]).compact.reject(&:blank?).uniq.each { |i| counts[i][key] += 1 }
    end
  end

  def self.case_worker_chart_data(scope)
    user_names = User.pluck(:user_name, :full_name).to_h
    counts = Hash.new { |h, k| h[k] = { label: user_names[k] || k.titleize, total: 0, open: 0, closed: 0 } }
    accumulate_case_workers(scope, counts)
    counts.sort_by { |_k, v| -v[:total] }.to_h
  end

  def self.accumulate_case_workers(scope, counts)
    scope.each do |c|
      user = c.data['owned_by']
      next if user.blank?

      key = c.data['status'] == 'closed' ? :closed : :open
      counts[user][:total] += 1
      counts[user][key] += 1
    end
  end

  def self.age_tallies(scope)
    { cases_per_age_groups: age_group_chart_data(scope) }
  end

  def self.age_group_chart_data(scope)
    counts = AGE_GROUPS.to_h { |g| [g, { open: 0, closed: 0 }] }
    accumulate_age_groups(scope, counts)
    counts
  end

  def self.accumulate_age_groups(scope, counts)
    scope.each do |c|
      group = determine_age_group(c.data['age'])
      key = c.data['status'] == 'closed' ? :closed : :open
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
