# frozen_string_literal: true

# Dedicated helper for NewDashboard location aggregations (District & Tehsil).
class NewDashboardLocationStats
  def self.chart_data(scope, level_index)
    locations = location_names_map
    counts = Hash.new { |h, k| h[k] = { open: 0, closed: 0 } }
    accumulate_counts(scope, locations, counts, level_index)
    counts.sort_by { |_k, v| -(v[:open] + v[:closed]) }.to_h
  end

  def self.accumulate_counts(scope, locations, counts, level_index)
    scope.each do |c|
      loc_name = locations[c.data['location_current']]
      next if loc_name.blank?

      val = loc_name.split(':')[level_index]&.strip
      counts[val][c.data['status'] == 'closed' ? :closed : :open] += 1 if val.present?
    end
  end

  def self.location_names_map
    Location.all.each_with_object({}) do |loc, h|
      name_en = loc.name_i18n&.[]('en') || loc.name_i18n&.values&.first
      h[loc.location_code] = name_en if loc.location_code.present?
    end
  end
end
