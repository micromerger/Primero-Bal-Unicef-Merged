# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

# ClientFeedbackResponseList
#
# A repository for ClientFeedbackResponse object. It provides methods
# for interacting with the list of responses in the language of the
# responses domain.
class Kpi::ClientFeedbackResponseList < ValueObject
  attr_accessor :responses

  def wrapped_responses
    @wrapped_responses ||= responses
                           .map { |response| Kpi::ClientFeedbackResponse.new(response:) }
  end

  def valid_responses?
    wrapped_responses.any?(&:valid_response?)
  end

  def satisfied
    wrapped_responses.count(&:satisfied?)
  end

  def unsatisfied
    wrapped_responses.count { |response| !response.satisfied? }
  end
end
