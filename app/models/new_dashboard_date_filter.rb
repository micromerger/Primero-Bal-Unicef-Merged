# frozen_string_literal: true

# Filters dashboard case records by registration date range.
class NewDashboardDateFilter
  def self.filter(list, date_from, date_to)
    return list if date_from.blank? && date_to.blank?

    from_d = parse_date(date_from)
    to_d = parse_date(date_to, is_end: true)

    list.select { |c| within_range?(c['registration_date'], from_d, to_d) }
  end

  def self.within_range?(date_val, from_d, to_d)
    reg = parse_date(date_val)
    return false if reg.nil?

    (from_d.nil? || reg >= from_d) && (to_d.nil? || reg <= to_d)
  end

  def self.parse_date(val, is_end: false)
    return nil if val.blank?
    return val if val.is_a?(Date)

    str = val.to_s.strip
    return parse_month(str, is_end) if str.match?(/^\d{4}-\d{2}$/)

    Date.parse(str)
  rescue ArgumentError, TypeError
    nil
  end

  def self.parse_month(str, is_end)
    d = Date.parse("#{str}-01")
    is_end ? d.end_of_month : d
  end
end
