class SendSmsJob < ApplicationJob
  queue_as :default

  def perform(record_id, current_user)
    data = Child.find_by(id: record_id)
    return unless data

    loc = data.location_current
    if loc.blank?
      Rails.logger.info "Child #{record_id} has no location, skipping job."
      return
    end

    location = Location.find_by(location_code: loc)
    loc = location&.hierarchy_path || loc

    if loc.nil?
      Rails.logger.info "Location hierarchy path is nil for Child #{record_id}, skipping job."
      return
    end

    Rails.logger.info "Location hierarchy path: #{loc}"

    path_elements = loc.split('.')
    third_value = path_elements[2] if path_elements.length > 2

    if third_value.blank?
      Rails.logger.info "District is missing in hierarchy path: #{loc}, skipping notifications."
      return
    end

    Rails.logger.info "District extracted: #{third_value}"

    dcpu_admin_role = Role.find_by(name: 'DCPU Admin')
    dcpu_admin_users = User.where(role: dcpu_admin_role)

    filtered_users = dcpu_admin_users.select do |user|
      user.location.present? &&
        user.location.to_s.strip.downcase == third_value.to_s.strip.downcase
    end

    if filtered_users.empty?
      Rails.logger.info "No DCPU Admin users found for district #{third_value}, skipping notifications."
      return
    end

    filtered_users_phone = filtered_users.map(&:phone)
    filtered_users_email = filtered_users.map(&:email)
    dcpu_admin_users_count = filtered_users.count

    Rails.logger.info "Hierarchy Path: #{loc}"
    Rails.logger.info "District: #{third_value}"
    Rails.logger.info "Count DCPU Admin of #{third_value}: #{dcpu_admin_users_count}"
    Rails.logger.info "Filtered Users Emails: #{filtered_users_email}"
    Rails.logger.info "Filtered Users Phones: #{filtered_users_phone}"

    UserMailer.notify_admin(filtered_users_email, record_id).deliver_now
    message = "New case with id #{record_id} is added in your district. Please attend to it. Thanks. Primero-CPIMS"
   # send_sms(filtered_users_phone, message)
  end

  private

  def send_sms(phone_numbers, message)
    email = "engineerusmanjutt@gmail.com"
    key   = "02486a8884addd72fd0a3a94d454f7bc28"
    mask  = "Digi SMS"

    phone_numbers.each do |phone|
      data = {
        email:   email,
        key:     key,
        mask:    mask,
        to:      phone,
        message: message
      }

      response = send_sms_request(data)
      Rails.logger.info "SMS Response for #{phone}: #{response}"
    end
  end

  def send_sms_request(data)
    uri = URI('https://secure.h3techs.com/sms/api/send')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request.set_form_data(data)

    response = http.request(request)
    response.body
  rescue => e
    Rails.logger.error("SMS sending failed: #{e.message}")
    nil
  end
end