# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

# This has to be after initialize because we need to load first the locale first
Rails.application.config.after_initialize do
  next unless ActiveRecord::Type::Boolean.new.cast(ENV.fetch('PRIMERO_GENERATE_LOCATIONS', nil)) == true

  Rails.logger.info 'Generating locations JSON file on server boot'
  begin
    if ActiveRecord::Base.connection.table_exists?(:locations) &&
       ActiveRecord::Base.connection.table_exists?(:system_settings)
      count_system_settings = ActiveRecord::Base.connection
                                                .select_all('SELECT COUNT(id) FROM locations')
                                                .rows.flatten.first
      count_locations = ActiveRecord::Base.connection
                                          .select_all('SELECT COUNT(id) FROM system_settings')
                                          .rows.flatten.first
      count_system_settings.positive? && count_locations.positive? && GenerateLocationFilesService.generate
    end
  rescue StandardError => e
    Rails.logger.error 'Locations options not generated'
    Rails.logger.error e.message
  end
end
