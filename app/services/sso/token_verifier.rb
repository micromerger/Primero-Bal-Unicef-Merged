# frozen_string_literal: true

# Copyright (c) 2014 - 2026 UNICEF. All rights reserved.

module Sso
  class TokenVerifier
    ALGORITHM = 'HS256'
    MAX_TOKEN_BYTES = 4096
    LEEWAY_SECONDS = 5

    class << self
      def verify(token)
        raise DisabledError, 'SSO is disabled' unless Config.enabled?
        raise InvalidTokenError, 'Token is missing' if token.blank?

        if token.bytesize > MAX_TOKEN_BYTES
          raise InvalidTokenError, 'Token exceeds maximum allowed size'
        end

        Config.validate_configuration!

        secret = Config.shared_secret

        begin
          payloads, _header = JWT.decode(
            token,
            secret,
            true,
            {
              algorithm: ALGORITHM,
              iss: Config.issuer,
              verify_iss: true,
              aud: Config.audience,
              verify_aud: true,
              verify_expiration: true,
              leeway: LEEWAY_SECONDS
            }
          )
          payload = payloads
        rescue JWT::ExpiredSignature => e
          raise InvalidTokenError, "Token has expired: #{e.message}"
        rescue JWT::InvalidIssuerError => e
          raise InvalidTokenError, "Invalid issuer: #{e.message}"
        rescue JWT::InvalidAudError => e
          raise InvalidTokenError, "Invalid audience: #{e.message}"
        rescue JWT::IncorrectAlgorithm => e
          raise InvalidTokenError, "Incorrect algorithm: #{e.message}"
        rescue JWT::DecodeError => e
          raise InvalidTokenError, "JWT decode error: #{e.message}"
        end

        jti = payload['jti']
        raise InvalidTokenError, 'Missing jti claim' if jti.blank?

        iat = payload['iat'].to_i
        exp = payload['exp'].to_i

        if iat > Time.now.to_i + LEEWAY_SECONDS
          raise InvalidTokenError, 'Token issued in the future beyond clock skew tolerance'
        end

        if exp > 0 && iat > 0
          token_lifetime = exp - iat
          max_ttl = Config.token_ttl
          if token_lifetime > max_ttl
            raise InvalidTokenError, 'Token lifetime exceeds maximum allowed TTL'
          end
        end

        remaining_ttl = [exp - Time.now.to_i, 1].max
        unless ReplayProtection.check_and_consume!(jti, remaining_ttl)
          raise InvalidTokenError, 'Token jti already consumed'
        end

        payload
      end
    end
  end
end
