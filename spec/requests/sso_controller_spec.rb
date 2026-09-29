require 'rails_helper'

RSpec.describe SsoController, type: :request do
  let(:secret) { 'test-shared-secret-key-32-bytes!!' }
  let(:issuer) { 'new-system' }
  let(:audience) { 'primero' }
  let(:ttl) { 60 }

  before do
    allow(Sso::Config).to receive(:enabled?).and_return(true)
    allow(Sso::Config).to receive(:shared_secret).and_return(secret)
    allow(Sso::Config).to receive(:issuer).and_return(issuer)
    allow(Sso::Config).to receive(:audience).and_return(audience)
    allow(Sso::Config).to receive(:token_ttl).and_return(ttl)
    Rails.cache.clear
  end

  def build_test_user(attributes = {})
    user_name = attributes[:user_name] || "sso_user_#{SecureRandom.hex(4)}"
    email = attributes[:email] || "#{user_name}@example.com"
    user = User.find_by(user_name: user_name) || User.find_by(email: email)
    return user if user

    role = Role.first || Role.new(name: 'Test Role', unique_id: 'test_role', permissions: { 'read' => true })
    role.save!(validate: false) if role.new_record?

    user = User.new(
      user_name: user_name,
      email: email,
      full_name: 'SSO Test User',
      password: 'Password123!',
      password_confirmation: 'Password123!',
      disabled: attributes.fetch(:disabled, false),
      unverified: attributes.fetch(:unverified, false),
      role: role
    )
    user.save!(validate: false)
    user
  end

  def generate_token(payload_overrides = {}, custom_secret = secret)
    now = Time.now.to_i
    payload = {
      iss: issuer,
      aud: audience,
      sub: 'sso_test_user',
      iat: now,
      exp: now + ttl,
      jti: SecureRandom.uuid
    }.merge(payload_overrides)

    JWT.encode(payload, custom_secret, 'HS256')
  end

  describe 'POST /sso/login' do
    let!(:user) { build_test_user(user_name: 'sso_test_user') }

    context 'Token transport & HTTP method constraints' do
      it 'rejects GET requests with 405 Method Not Allowed' do
        get '/sso/login'
        expect(response.status).to eq(405)
      end

      it 'rejects JWT passed via URL query string parameter with generic 401' do
        token = generate_token
        post "/sso/login?token=#{token}"

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end

      it 'accepts JWT passed in Authorization Bearer header' do
        token = generate_token
        post '/sso/login', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to redirect_to(root_path)
        expect(controller.current_user).to eq(user)
      end

      it 'accepts JWT passed in POST request body' do
        token = generate_token
        post '/sso/login', params: { token: token }

        expect(response).to redirect_to(root_path)
        expect(controller.current_user).to eq(user)
      end
    end

    context 'when SSO is disabled' do
      before do
        allow(Sso::Config).to receive(:enabled?).and_return(false)
      end

      it 'rejects authentication with generic 401' do
        token = generate_token
        post '/sso/login', params: { token: token }

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end
    end

    context 'with valid token' do
      it 'logs in the user and redirects to root path (HTML)' do
        token = generate_token
        post '/sso/login', params: { token: token }

        expect(response).to redirect_to(root_path)
        expect(controller.current_user).to eq(user)
      end

      it 'logs in the user and redirects to return_to parameter if valid relative path' do
        token = generate_token
        post '/sso/login', params: { token: token, return_to: '/cases' }

        expect(response).to redirect_to('/cases')
        expect(controller.current_user).to eq(user)
      end

      it 'logs in the user and returns minimal JSON response without internal user_id' do
        token = generate_token
        post '/sso/login', params: { token: token }, headers: { 'ACCEPT' => 'application/json' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['redirect_url']).to eq(root_path)
        expect(json.keys).to match_array(['success', 'redirect_url'])
      end

      it 'finds user by email if sub matches email' do
        email_user = build_test_user(user_name: 'email_user', email: 'email_user@example.com')
        token = generate_token(sub: 'email_user@example.com')

        post '/sso/login', params: { token: token }
        expect(response).to redirect_to(root_path)
        expect(controller.current_user).to eq(email_user)
      end

      it 'allows small clock-skew tolerance within 5 second leeway' do
        now = Time.now.to_i
        token = generate_token(iat: now + 3, exp: now + ttl + 3)

        post '/sso/login', params: { token: token }
        expect(response).to redirect_to(root_path)
      end
    end

    context 'Security protections & generic error responses' do
      it 'rejects missing token with generic 401' do
        post '/sso/login', params: {}

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end

      it 'rejects token signed with wrong secret with generic 401' do
        token = generate_token({}, 'wrong-secret-key-1234567890123')
        post '/sso/login', params: { token: token }

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end

      it 'rejects expired token with generic 401' do
        token = generate_token(iat: Time.now.to_i - 120, exp: Time.now.to_i - 60)
        post '/sso/login', params: { token: token }

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end

      it 'rejects token with wrong issuer with generic 401' do
        token = generate_token(iss: 'wrong-issuer')
        post '/sso/login', params: { token: token }

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end

      it 'rejects token with wrong audience with generic 401' do
        token = generate_token(aud: 'wrong-audience')
        post '/sso/login', params: { token: token }

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end

      it 'rejects token issued beyond clock-skew leeway with generic 401' do
        now = Time.now.to_i
        token = generate_token(iat: now + 15, exp: now + ttl + 15)
        post '/sso/login', params: { token: token }

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end

      it 'rejects token exceeding maximum allowed TTL (exp - iat > max_ttl) with generic 401' do
        now = Time.now.to_i
        token = generate_token(iat: now, exp: now + ttl + 120)
        post '/sso/login', params: { token: token }

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end

      it 'rejects oversized token exceeding 4096 bytes with generic 401' do
        huge_padding = 'x' * 5000
        token = generate_token(padding: huge_padding)
        post '/sso/login', params: { token: token }

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end

      it 'rejects replayed token (jti already consumed) with generic 401' do
        jti = SecureRandom.uuid
        token1 = generate_token(jti: jti)
        token2 = generate_token(jti: jti)

        post '/sso/login', params: { token: token1 }
        expect(response).to redirect_to(root_path)

        post '/sso/login', params: { token: token2 }
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end
    end

    context 'Configuration validation' do
      it 'rejects authentication when shared secret is missing' do
        allow(Sso::Config).to receive(:shared_secret).and_return(nil)
        token = generate_token
        post '/sso/login', params: { token: token }

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end
    end

    context 'with invalid user state' do
      it 'rejects unknown user with generic 401' do
        token = generate_token(sub: 'non_existent_user')
        post '/sso/login', params: { token: token }

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end

      it 'rejects disabled user with generic 401' do
        disabled_user = build_test_user(user_name: 'disabled_user', disabled: true)
        token = generate_token(sub: 'disabled_user')

        post '/sso/login', params: { token: token }

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end

      it 'rejects unverified user with generic 401' do
        unverified_user = build_test_user(user_name: 'unverified_user', unverified: true)
        token = generate_token(sub: 'unverified_user')

        post '/sso/login', params: { token: token }

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Authentication failed')
      end
    end
  end

  describe 'Atomic concurrent replay protection unit test' do
    it 'ensures only one concurrent request can consume the same jti' do
      jti = "concurrent-test-#{SecureRandom.uuid}"
      results = []
      threads = []

      5.times do
        threads << Thread.new do
          results << Sso::ReplayProtection.check_and_consume!(jti, 60)
        end
      end
      threads.each(&:join)

      expect(results.count(true)).to eq(1)
      expect(results.count(false)).to eq(4)
    end
  end

  describe 'Existing authentication workflow compatibility' do
    it 'does not alter standard Devise authentication endpoint' do
      post '/api/v2/tokens', params: { user_name: 'invalid', password: 'invalid' }
      expect([401, 422, 400]).to include(response.status)
    end
  end
end
