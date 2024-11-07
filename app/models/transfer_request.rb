# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

# Class for Transfer Request
class TransferRequest < Transition
  def perform
    self.status = Transition::STATUS_INPROGRESS
    # TODO: Add alert on referrals and transfers form for record
    record.update_last_updated_by(transitioned_by_user)
  end

  def respond!(params)
    status = params[:status]
    return if status == self.status

    case status
    when Transition::STATUS_ACCEPTED
      accept!
    when Transition::STATUS_REJECTED
      self.rejected_reason = params[:rejected_reason]
      reject!
    end
  end

  def accept!
    self.status = Transition::STATUS_ACCEPTED
    save!
    Transfer.create!(
      transitioned_to: transitioned_by, transitioned_by: transitioned_to,
      notes:, transitioned_to_agency:,
      record:, consent_overridden: consent_individual_transfer
    )
  end

  def reject!
    self.status = Transition::STATUS_REJECTED
    save!
  end

  def consent_given?
    true
  end

  def user_can_receive?
    super && (record.owned_by == transitioned_to)
  end

  def notify
    RequestTransferJob.perform_later(id)
  end
end
