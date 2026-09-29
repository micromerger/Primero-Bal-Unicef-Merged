# frozen_string_literal: true

# Copyright (c) 2014 - 2026 UNICEF. All rights reserved.

class SsoController < ApplicationController
  # CSRF exemption is strictly limited to POST /sso/login.
  # Rationale: This endpoint is an initial Single Sign-On (SSO) entry point receiving
  # signed JWT authentication tokens initiated from external systems (cross-origin POST).
  # Security is maintained via JWT signature verification, short-lived expiration, and single-use JTI replay protection.
  skip_before_action :verify_authenticity_token, only: [:login]

  before_action :enforce_https_in_production, only: [:login]

  def login
    token = extract_token
    user = Sso::AuthenticationService.authenticate(token)

    sign_in(:user, user)
    store_session_metadata
    log_audit_success(user)

    redirect_target = valid_return_to(params[:return_to]) || '/v2/cases'

    respond_to do |format|
      format.html { redirect_to redirect_target }
      format.json do
        render json: {
          success: true,
          redirect_url: redirect_target
        }, status: :ok
      end
    end
  rescue Sso::DisabledError => e
    Rails.logger.warn("[SSO] Request rejected: SSO is disabled (#{e.message})")
    render_generic_unauthorized
  rescue Sso::InvalidTokenError => e
    Rails.logger.warn("[SSO] Authentication failed: #{e.message}")
    render_generic_unauthorized
  rescue StandardError => e
    Rails.logger.error("[SSO] Unexpected error during SSO login: #{e.class.name} - #{e.message}")
    render_generic_unauthorized
  end

  private

  def extract_token
    # Reject token in URL query parameters
    if request.query_parameters.key?('token') || request.query_parameters.key?(:token)
      raise Sso::InvalidTokenError, 'Token in URL query parameters is not permitted'
    end

    # 1. Authorization Bearer header
    auth_header = request.headers['Authorization']
    if auth_header.present? && auth_header.start_with?('Bearer ')
      token = auth_header.split(' ', 2).last.to_s.strip
      return token if token.present?
    end

    # 2. POST body parameter
    token = request.request_parameters['token'] || request.request_parameters[:token]
    return token if token.present?

    nil
  end

  def valid_return_to(path)
    return nil if path.blank?
    return path if path.start_with?('/v2/') || path == '/v2'
    return "/v2#{path}" if path.start_with?('/') && !path.start_with?('//') && !path.include?(':')
    nil
  end

  def enforce_https_in_production
    return unless Rails.env.production?

    unless request.ssl?
      render_generic_unauthorized
    end
  end

  def store_session_metadata
    session[:ip_address] = LogUtils.remote_ip(request) if session[:ip_address].blank?
    session[:user_agent] = request.user_agent if session[:user_agent].blank?
  end

  def log_audit_success(user)
    AuditLogJob.perform_later(
      record_type: User.name,
      record_id: user.id,
      action: AuditLog::LOGIN,
      user_id: user.id,
      resource_url: request.original_url,
      metadata: {
        user_name: user.user_name,
        remote_ip: LogUtils.remote_ip(request),
        auth_type: 'sso'
      }
    )
  end

  def render_generic_unauthorized
    respond_to do |format|
      format.html { render plain: 'Authentication failed', status: :unauthorized }
      format.json { render json: { error: 'Authentication failed' }, status: :unauthorized }
    end
  end
end
