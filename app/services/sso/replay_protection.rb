# frozen_string_literal: true

# Copyright (c) 2014 - 2026 UNICEF. All rights reserved.

module Sso
  class ReplayProtection
    CACHE_KEY_PREFIX = 'sso:jti:'

    class << self
      def check_and_consume!(jti, ttl = Config.token_ttl)
        return false if jti.blank?

        key = "#{CACHE_KEY_PREFIX}#{jti}"
        ttl_seconds = [ttl.to_i, 1].max

        # Atomic set-if-absent operation provided by ActiveSupport::Cache::Store
        # Returns true if key was set (absent previously), false if key already exists.
        written = Rails.cache.write(key, Time.now.to_i, expires_in: ttl_seconds.seconds, unless_exist: true)
        written == true
      end
    end
  end
end
