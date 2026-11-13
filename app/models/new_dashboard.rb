# frozen_string_literal: true

# Dedicated model for New Dashboard metrics and case statistics.
# Encapsulates case aggregation logic without altering core Child or Dashboard models.
class NewDashboard
  attr_reader :user, :record_state, :scope

  def initialize(user = nil, record_state: true)
    @user = user
    @record_state = record_state
    @scope = record_state ? Child.where("data @? '$.record_state ? (@ == true || @ == \"true\")'") : Child.all
  end

  def total_cases
    @scope.count
  end

  def open_cases
    @scope.where("data @? '$.status ? (@ == \"open\")'").count
  end

  def closed_cases
    @scope.where("data @? '$.status ? (@ == \"closed\")'").count
  end

  def cases_by_status_and_sex
    counts = @scope.pluck(Arel.sql("data->>'status'"), Arel.sql("data->>'sex'")).tally
    {
      open_male: counts[%w[open male]] || 0, closed_male: counts[%w[closed male]] || 0,
      open_female: counts[%w[open female]] || 0, closed_female: counts[%w[closed female]] || 0,
      open_transgender: counts[%w[open transgender_baf5dac]] || 0,
      closed_transgender: counts[%w[closed transgender_baf5dac]] || 0
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
    NewDashboardCategoryStats.chart_data(@scope)
  end

  def services_chart_data
    names = service_type_names
    counts = Hash.new { |h, k| h[k] = { label: names[k] || k.titleize, open: 0, closed: 0 } }
    accumulate_services(counts)
    counts.sort_by { |_k, v| -(v[:open] + v[:closed]) }.to_h
  end

  def accumulate_services(counts)
    @scope.each do |c|
      st_list = Array(c.data['services_section']).map { |s| s['service_type'] }.compact.uniq
      key = c.data['status'] == 'closed' ? :closed : :open
      st_list.each { |st| counts[st][key] += 1 }
    end
  end

  def service_type_names
    Lookup.find_by(unique_id: 'lookup-service-type')&.lookup_values
          &.each_with_object({}) { |v, h| h[v['id']] = v['display_text'] } || {}
  end

  def nature_of_cases_chart_data
    counts = @scope.pluck(Arel.sql("data->>'risk_level'")).compact.reject(&:blank?).tally
    total = [counts.values.sum.to_f, 1.0].max
    counts.transform_values { |count| gender_entry(count, total) }
  end

  def monthly_trend_chart_data
    records = @scope.pluck(Arel.sql("data->>'registration_date'"), Arel.sql("data->>'status'"))
    records.each_with_object({}) do |(date, status), acc|
      next if date.blank?

      m = date.to_s[0..6]
      acc[m] ||= { total: 0, open: 0, closed: 0 }
      acc[m][:total] += 1
      acc[m][status == 'closed' ? :closed : :open] += 1
    end.sort.to_h
  end

  def gender_chart_data
    counts = @scope.pluck(Arel.sql("data->>'sex'")).compact.reject(&:blank?).tally
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
    records = @scope.pluck(Arel.sql("data->>'source_of_information_4442e8c'"), Arel.sql("data->>'status'"))
    records.each do |source, status|
      next if source.blank?

      key = status == 'closed' ? :closed : :open
      counts[source][key] += 1
    end
  end

  def source_of_information_names
    Lookup.find_by(id: 329)&.lookup_values
          &.each_with_object({}) { |v, h| h[v['id']] = v['display_text'] } || {}
  end

  private

  def gender_entry(count, total)
    { count: count || 0, percentage: (((count || 0) / total) * 100).round }
  end
end
