# frozen_string_literal: true

# This service is for sending notifications when an alert with send_email: true is created.
class AlertNotificationService
  attr_accessor :record_id, :alert_id, :user_name

  def initialize(record_id, alert_id, user_name)
    self.record_id = record_id
    self.alert_id = alert_id
    self.user_name = user_name
  end

  def key
    # This should return alert_case or alert_incident or similar based on the record type.
    "alert_#{record.class.parent_form}"
  end

  def user
    @user ||= User.find_by(user_name:)
    log_not_found('User', user_name) if @user.blank?
    @user
  end

  def alert
    @alert ||= Alert.find_by(id: alert_id)
    log_not_found('Alert', alert_id) if @alert.blank?
    @alert
  end

  def record
    @record ||= alert&.record
    log_not_found('Record', alert&.record_id) if @record.blank?
    @record
  end

  def locale
    @locale ||= user&.locale || I18n.locale
  end

  def form_section
    @form_section ||= FormSection.find_by(unique_id: alert.form_sidebar_id)
  end

  def record_type_translated
    I18n.t("forms.record_types.#{record.class.parent_form}", locale:)
  end

  def form_section_name_translated
    @form_section_name_translated ||= I18n.with_locale(locale) { form_section&.name }
  end

  def send_notification?
    # We may want to add some checks here if users can opt out of particular
    # types of notifications in the future.
    true
  end

  # This is for the message structure in push notifications
  alias type form_section_name_translated

  def subject
    I18n.t(
      'email_notification.alert_subject',
      record_type: record_type_translated,
      id: record.short_id,
      form_name: form_section_name_translated,
      locale:
    )
  end

  private

  def log_not_found(type, id)
    Rails.logger.error(
      "Notification not sent. #{type.capitalize} #{id} not found."
    )
  end
end
