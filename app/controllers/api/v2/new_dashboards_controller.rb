# frozen_string_literal: true

# Dedicated API controller for New Dashboard and charts.
# Provides endpoints without modifying existing controllers.
class Api::V2::NewDashboardsController < ApplicationApiController
  skip_after_action :write_audit_log, only: [:index]

  def index
    render json: cached_dashboard_payload(dashboard_params)
  end

  def model_class
    NewDashboard
  end

  private

  def record_state_param
    params[:record_state].nil? || params[:record_state].to_s == 'true'
  end

  def dashboard_params
    {
      record_state: record_state_param, district: params[:district].presence,
      date_from: params[:date_from].presence, date_to: params[:date_to].presence,
      force_refresh: params[:refresh].to_s == 'true'
    }
  end

  def cache_key_for(opts)
    scope_tag = "#{opts[:record_state]}_#{opts[:district]}"
    range_tag = "#{opts[:date_from]}_#{opts[:date_to]}"
    "new_dashboard_#{scope_tag}_#{range_tag}_u#{current_user&.id}"
  end

  def cached_dashboard_payload(opts)
    cache_key = cache_key_for(opts)
    Rails.cache.delete(cache_key) if opts[:force_refresh]

    Rails.cache.fetch(cache_key, expires_in: 2.minutes) do
      dashboard = NewDashboard.new(current_user, opts)
      { metadata: dashboard_metadata(dashboard, opts[:record_state]), charts: dashboard.chart_data }
    end
  end

  def dashboard_metadata(dashboard, record_state)
    counts = { total: dashboard.total_cases, open: dashboard.open_cases, closed: dashboard.closed_cases }
    info = { record_state: record_state, district: dashboard.district,
             date_from: dashboard.date_from, date_to: dashboard.date_to,
             districts: NewDashboardLocationStats.all_districts }
    counts.merge(info).merge(dashboard.cases_by_status_and_sex).merge(per: 1, page: 1)
  end
end
