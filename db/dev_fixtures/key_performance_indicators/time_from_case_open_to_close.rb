# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

require_relative 'setup'

#  create 100 cases with the time between the case opening
# and the time the case closed ditributed around 1-3 months
101.times do |_index|
  days = sample_box_muller(1, 365, 75, 30).round
  puts "Creating case #{days} days in the past that closes today"
  child = Child.new_with_user(TEST_USER, {})
  child.save!
  child.created_at = Date.today.prev_day(days).to_time
  child.date_closure = Date.today
  child.save!
end

puts 'Created 100 cases created between 1 and 365 days ago and closed today.'
