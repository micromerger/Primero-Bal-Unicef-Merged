class SendSmsJob < ApplicationJob
    queue_as :default
    def perform(record_id, current_user)
    data = Child.find(record_id)
    loc = data.location_current
    puts "location #{loc}"
    location = Location.find_by(location_code: loc)
    if location && location.respond_to?(:hierarchy_path)
    loc = location.hierarchy_path
    else
    puts "Location hierarchy path is already a string: #{loc}"
    end
    puts "location #{loc}"
    if loc.nil?
  puts "Location hierarchy path is nil, skipping job."
  return
end

path_elements = loc.split('.')
    third_value = if path_elements.length > 2
    path_elements[2]
    elsif path_elements.length > 1
    #path_elements[1]
    else
    #path_elements.last
    end
    # Skip sending if third_value is nil or empty
    if third_value.blank?
        puts "Hierarchy Path: #{loc}"
    
        puts "Skipping email and SMS sending as District is empty."
        return
      end
    puts "Location Third value: #{third_value}"
    dcpu_admin_role = Role.find_by(name: 'DCPU Admin')
    dcpu_admin_users = User.where(role: dcpu_admin_role)
    filtered_users = dcpu_admin_users.select do |user|
    user.location && third_value.include?(user.location)
    end
    filtered_users_phone = filtered_users.map(&:phone)
    filtered_users_email = filtered_users.map(&:email)
    dcpu_admin_users_count = filtered_users.count
    puts "Hierarchy Path: #{loc}"
    puts "District: #{third_value}"
    puts "Count DCPU Admin of #{third_value}: #{dcpu_admin_users_count}"
    puts "Filtered Users Emails: #{filtered_users_email}"
    puts "Filtered Users Phones: #{filtered_users_phone}"
    UserMailer.notify_admin(filtered_users_email, record_id).deliver_now
        # Send SMS to filtered users
        message = "New case with id #{record_id} is added in your district. Please attend to it. Thanks. Primero-CPIMS"
    #    send_sms(filtered_users_phone, message)
    end
    private
    
      def send_sms(phone_numbers, message)
        email = "engineerusmanjutt@gmail.com"
        key = "02486a8884addd72fd0a3a94d454f7bc28"
        mask = "Digi SMS"
    
        phone_numbers.each do |phone|
          data = {
            email: email,
            key: key,
            mask: mask,
            to: phone,
            message: message
          }
    
          response = send_sms_request(data)
          puts "SMS Response for #{phone}: #{response}"
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
      end
    end
    