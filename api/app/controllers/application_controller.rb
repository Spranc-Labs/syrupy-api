# This is the superclass of all controllers in the application, defining various
# defaults and helper methods.
class ApplicationController < ActionController::API
  # For lograge logs.
  # If you add something, here, you may need to also update
  # config/application.rb -> config.lograge.custom_options
  def append_info_to_payload(payload)
    super
    payload[:response_body] = response.body
    payload[:ip] = request.remote_ip
    payload[:user_id] = Current.user&.id || "none"
    payload[:user_name] = Current.user&.full_name || "none"
  end
end 