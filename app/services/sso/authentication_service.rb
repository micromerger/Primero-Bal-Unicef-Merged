# frozen_string_literal: true

# Copyright (c) 2014 - 2026 UNICEF. All rights reserved.

module Sso
  class AuthenticationService
    class << self
      def authenticate(token)
        payload = TokenVerifier.verify(token)
        user_identifier = payload['sub']

        raise InvalidTokenError, 'Missing sub (user identifier) claim' if user_identifier.blank?

        user = User.find_by(user_name: user_identifier) || User.find_by(email: user_identifier)
        raise InvalidTokenError, 'User not found' if user.nil?
        raise InvalidTokenError, 'User is inactive or disabled' unless user.active_for_authentication?

        user
      end
    end
  end
end
