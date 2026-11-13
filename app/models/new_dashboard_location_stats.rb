# frozen_string_literal: true

# Dedicated helper for NewDashboard location aggregations (District & Tehsil).
class NewDashboardLocationStats
  def self.chart_data(scope_or_list, level_index, locations = nil)
    locations ||= location_names_map
    counts = Hash.new { |h, k| h[k] = { open: 0, closed: 0 } }
    accumulate_counts(scope_or_list, locations, counts, level_index)
    counts.sort_by { |_k, v| -(v[:open] + v[:closed]) }.to_h
  end

  def self.accumulate_counts(scope_or_list, locations, counts, level_index)
    scope_or_list.each do |c|
      data = c.is_a?(Hash) ? c : c.data
      loc_name = locations[data['location_current']]
      next if loc_name.blank?

      val = loc_name.split(':')[level_index]&.strip
      counts[val][data['status'] == 'closed' ? :closed : :open] += 1 if val.present?
    end
  end

  def self.location_names_map
    Location.pluck(:location_code, :name_i18n).each_with_object({}) do |(code, name_i18n), h|
      name_en = name_i18n&.[]('en') || name_i18n&.values&.first
      h[code] = name_en if code.present?
    end
  end

  def self.all_districts
    location_names_map.values.map { |v| v.split(':')[2]&.strip }.compact.reject(&:blank?).uniq.sort
  end
end
