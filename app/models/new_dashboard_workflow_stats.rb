# frozen_string_literal: true

# Dedicated helper for NewDashboard workflow stage aggregations.
class NewDashboardWorkflowStats
  WORKFLOW_STAGES = %w[
    new
    assessment
    case_plan
    service_provision
    services_implemented
  ].freeze

  def self.chart_data(scope)
    counts = WORKFLOW_STAGES.to_h { |stage| [stage, 0] }
    accumulate_counts(scope, counts)
    counts
  end

  def self.accumulate_counts(scope, counts)
    scope.each do |c|
      next unless c.data['status'] == 'open'

      stage = c.data['workflow']
      counts[stage] += 1 if counts.key?(stage)
    end
  end
end
