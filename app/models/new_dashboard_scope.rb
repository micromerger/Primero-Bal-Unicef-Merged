# frozen_string_literal: true

# Builds user-permitted and record-state scoped queries for NewDashboard.
class NewDashboardScope
  def self.build(user, record_state)
    base = record_state ? Child.where("data @? '$.record_state ? (@ == true || @ == \"true\")'") : Child.all
    return base unless user.respond_to?(:record_query_scope)

    apply_user_scope(base, user)
  end

  def self.apply_user_scope(base, user)
    scope_hash = user.record_query_scope(Child)
    filters = Search::SearchScope.scope_filters(scope_hash)
    filters.reduce(base) { |rel, filter| rel.where(filter.query(Child)) }
  rescue StandardError => e
    Rails.logger.error("NewDashboardScope error: #{e.message}")
    base
  end
end
