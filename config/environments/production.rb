# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

Rails.application.configure do
  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = 'X-Sendfile'
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # When running on the UNICEF Azure SaaS, Rails needs to serve its assets.
  # When running in standalone mode, nginx will serve the assets.
  config.public_file_server.enabled = ActiveRecord::Type::Boolean.new.cast(ENV.fetch('RAILS_PUBLIC_FILE_SERVER', nil))

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.eager_load = true

  config.filter_parameters += %i[child incident tracing_request]

  if ENV['LOG_TO_STDOUT'].present?
    $stdout.sync = true
    logger = ActiveSupport::Logger.new($stdout)
    logger.formatter = Logger::Formatter.new
    config.logger = ActiveSupport::TaggedLogging.new(logger)
    config.log_tags = [
      :request_id, ->(_request) { LogUtils.thread_id }, ->(request) { LogUtils.remote_ip(request) }
    ]
  end

  config.force_ssl = true
  config.ssl_options = { redirect: false }

  storage_type = %w[local microsoft amazon minio].find do |t|
    t == ENV['PRIMERO_STORAGE_TYPE']
  end || 'local'
  config.active_storage.service = storage_type.to_sym

  config.active_job.queue_adapter = :delayed_job
end
