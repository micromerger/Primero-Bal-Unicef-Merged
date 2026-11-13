# frozen_string_literal: true

# Dedicated helper for NewDashboard workflow stage aggregations.
class NewDashboardWorkflowStats
  WORKFLOW_STAGES = %w[
    new
    assessment
    case_plan
    service_provision
    services_implemented
    reopened
  ].freeze

  def self.chart_data(scope_or_list)
    counts = WORKFLOW_STAGES.to_h { |stage| [stage, 0] }
    accumulate_counts(scope_or_list, counts)
    counts
  end

  def self.accumulate_counts(scope_or_list, counts)
    scope_or_list.each do |c|
      data = c.is_a?(Hash) ? c : c.data
      next unless data['status'] == 'open'

      stage = data['workflow']
      counts[stage] += 1 if counts.key?(stage)
    end
  end
end
