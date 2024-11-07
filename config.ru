# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

# This file is used by Rack-based servers to start the application.
# Setting PRIMERO_WAIT_FOR_DB for all server processes.
# We should only wait for for the database when we launch daemons or the app server.
ENV['PRIMERO_WAIT_FOR_DB'] = 'true'
ENV['PRIMERO_GENERATE_LOCATIONS'] ||= 'true'
require File.expand_path('config/environment', __dir__)
run Rails.application
