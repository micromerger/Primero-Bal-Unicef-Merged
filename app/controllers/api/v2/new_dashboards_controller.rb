# frozen_string_literal: true

# Dedicated API controller for New Dashboard and charts.
# Provides endpoints without modifying existing controllers.
class Api::V2::NewDashboardsController < ApplicationApiController
  skip_after_action :write_audit_log, only: [:index]

  def index
    record_state = params[:record_state].nil? || params[:record_state].to_s == 'true'
    dashboard = NewDashboard.new(current_user, record_state: record_state)

    render json: {
      metadata: dashboard_metadata(dashboard, record_state),
      charts: dashboard.chart_data
    }
  end

  def model_class
    NewDashboard
  end

  private

  def dashboard_metadata(dashboard, record_state)
    status_and_sex = dashboard.cases_by_status_and_sex
    {
      total: dashboard.total_cases,
      open: dashboard.open_cases,
      closed: dashboard.closed_cases,
      record_state: record_state,
      per: 1,
      page: 1
    }.merge(status_and_sex)
  end
end
