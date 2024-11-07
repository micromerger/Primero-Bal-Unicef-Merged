# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

# Records that use this module have request approval and approval capabilities
module Approvable
  extend ActiveSupport::Concern

  included do
    store_accessor :data, :assessment_approved, :case_plan_approved, :closure_approved, :action_plan_approved,
                   :gbv_closure_approved, :approval_status_assessment, :approval_status_case_plan,
                   :approval_status_closure, :approval_status_action_plan, :approval_status_gbv_closure,
                   :case_plan_approval_type, :assessment_approved_date, :closure_approved_date,
                   :case_plan_approved_date, :action_plan_approved_date, :gbv_closure_approved_date,
                   :assessment_approved_comments, :case_plan_approved_comments, :closure_approved_comments,
                   :action_plan_approved_comments, :gbv_closure_approved_comments, :approval_subforms

    after_save_commit :send_approval_mail
  end

  def send_approval_mail
    return if approval_subforms.blank? || saved_changes_to_record.keys.exclude?('approval_subforms')

    approval = approval_subforms.last
    if approval['approval_requested_for'].present?
      send_approval_request_mail(approval)
    else
      send_approval_response_mail(approval)
    end
  end

  def send_approval_request_mail(approval)
    managers = owner.managers.select(&:emailable?)
    if managers.blank?
      Rails.logger.info "Approval Request Mail not sent. No managers present with send_mail enabled. User [#{owner.id}]"
      return
    end
    managers.each do |manager|
      ApprovalRequestJob.perform_later(id, approval['approval_requested_for'], manager.user_name)
    end
  end

  def send_approval_response_mail(approval)
    ApprovalResponseJob.perform_later(id, send("#{approval['approval_response_for']}_approved"),
                                      approval['approval_for_type'], approval['approved_by'])
  end
end
