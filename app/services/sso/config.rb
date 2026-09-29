# frozen_string_literal: true

# Copyright (c) 2014 - 2026 UNICEF. All rights reserved.

module Sso
  class InvalidTokenError < StandardError; end
  class DisabledError < StandardError; end

  class Config
    class << self
      def enabled?
        ActiveRecord::Type::Boolean.new.cast(ENV.fetch('PRIMERO_SSO_ENABLED', false)) == true
      end

      def shared_secret
        ENV.fetch('PRIMERO_SSO_SHARED_SECRET', nil)
      end

      def issuer
        ENV.fetch('PRIMERO_SSO_ISSUER', 'new-system')
      end

      def audience
        ENV.fetch('PRIMERO_SSO_AUDIENCE', 'primero')
      end

      def token_ttl
        ENV.fetch('PRIMERO_SSO_TOKEN_TTL', '60').to_i
      end

      def validate_configuration!
        return unless enabled?

        raise InvalidTokenError, 'SSO shared secret is not configured' if shared_secret.blank?
        raise InvalidTokenError, 'SSO issuer is not configured' if issuer.blank?
        raise InvalidTokenError, 'SSO audience is not configured' if audience.blank?
      end
    end
  end
end
