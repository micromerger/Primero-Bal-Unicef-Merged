# frozen_string_literal: true

# Dedicated model for New Dashboard metrics and case statistics.
# Encapsulates case aggregation logic without altering core Child or Dashboard models.
class NewDashboard
  attr_reader :user, :record_state, :district, :date_from, :date_to, :scope

  def initialize(user = nil, options = {})
    @user = user
    @record_state = options.fetch(:record_state, true)
    @district = options[:district].presence
    @date_from = options[:date_from].presence
    @date_to = options[:date_to].presence
    @scope = NewDashboardScope.build(user, @record_state)
  end

  def total_cases
    case_data_list.size
  end

  def open_cases
    case_data_list.count { |c| c['status'] == 'open' }
  end

  def closed_cases
    case_data_list.count { |c| c['status'] == 'closed' }
  end

  def cases_by_status_and_sex
    counts = Hash.new(0)
    case_data_list.each { |c| counts[[c['status'], c['sex']]] += 1 }
    {
      open_male: counts[%w[open male]],
      closed_male: counts[%w[closed male]],
      open_female: counts[%w[open female]],
      closed_female: counts[%w[closed female]],
      open_transgender: counts[%w[open transgender_baf5dac]],
      closed_transgender: counts[%w[closed transgender_baf5dac]]
    }
  end

  def chart_data
    {
      total_cases: total_cases, open_cases: open_cases, closed_cases: closed_cases,
      cases_by_status: { 'open' => open_cases, 'closed' => closed_cases },
      cases_by_status_and_sex: cases_by_status_and_sex, source_of_information: source_of_information_chart_data,
      cases_per_gender: gender_chart_data, cases_per_month_year: monthly_trend_chart_data,
      nature_of_cases: nature_of_cases_chart_data, cases_per_services_provided: services_chart_data
    }.merge(category_charts)
  end

  def category_charts
    NewDashboardCategoryStats.chart_data(case_data_list)
  end

  def services_chart_data
    names = service_type_names
    counts = Hash.new { |h, k| h[k] = { label: names[k] || k.titleize, open: 0, closed: 0 } }
    accumulate_services(counts)
    counts.sort_by { |_k, v| -(v[:open] + v[:closed]) }.to_h
  end

  def accumulate_services(counts)
    case_data_list.each do |c|
      key = c['status'] == 'closed' ? :closed : :open
      Array(c['services_section']).each { |s| counts[s['service_type']][key] += 1 if s['service_type'].present? }
    end
  end

  def service_type_names
    Lookup.find_by(unique_id: 'lookup-service-type')&.lookup_values
          &.each_with_object({}) { |v, h| h[v['id']] = v['display_text'] } || {}
  end

  def nature_of_cases_chart_data
    counts = Hash.new(0)
    case_data_list.each do |c|
      risk = c['risk_level']
      counts[risk] += 1 if risk.present?
    end
    total = [counts.values.sum.to_f, 1.0].max
    counts.transform_values { |count| gender_entry(count, total) }
  end

  def monthly_trend_chart_data
    case_data_list.each_with_object({}) do |c, acc|
      date = c['registration_date']
      next if date.blank?

      m = date.to_s[0..6]
      acc[m] ||= { total: 0, open: 0, closed: 0 }
      acc[m][:total] += 1
      acc[m][c['status'] == 'closed' ? :closed : :open] += 1
    end.sort.to_h
  end

  def gender_chart_data
    counts = Hash.new(0)
    case_data_list.each do |c|
      sex = c['sex']
      counts[sex] += 1 if sex.present?
    end
    total = [counts.values.sum.to_f, 1.0].max
    counts.transform_values { |count| gender_entry(count, total) }
  end

  def source_of_information_chart_data
    names = source_of_information_names
    counts = Hash.new { |h, k| h[k] = { label: names[k] || k.titleize, open: 0, closed: 0 } }
    accumulate_sources(counts)
    counts.sort_by { |_k, v| -(v[:open] + v[:closed]) }.to_h
  end

  def accumulate_sources(counts)
    case_data_list.each do |c|
      source = c['source_of_information_4442e8c']
      next if source.blank?

      key = c['status'] == 'closed' ? :closed : :open
      counts[source][key] += 1
    end
  end

  def source_of_information_names
    Lookup.find_by(id: 329)&.lookup_values
          &.each_with_object({}) { |v, h| h[v['id']] = v['display_text'] } || {}
  end

  def case_data_list
    @case_data_list ||= begin
      list = @scope.pluck(:data)
      list = filter_by_district(list)
      NewDashboardDateFilter.filter(list, @date_from, @date_to)
    end
  end

  private

  def filter_by_district(list)
    return list if @district.blank?

    locations = NewDashboardLocationStats.location_names_map
    list.select do |c|
      loc_name = locations[c['location_current']]
      loc_name.present? && loc_name.split(':')[2]&.strip == @district
    end
  end

  def gender_entry(count, total)
    { count: count || 0, percentage: (((count || 0) / total) * 100).round }
  end
end
