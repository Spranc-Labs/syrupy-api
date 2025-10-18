# frozen_string_literal: true

class JwtService
  SECRET_KEY = Rails.application.secret_key_base.to_s

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.encode_refresh_token(payload, exp = 7.days.from_now)
    payload[:exp] = exp.to_i
    payload[:type] = 'refresh'
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT decode error: #{e.message}"
    nil
  end

  def self.refresh_access_token(refresh_token)
    payload = decode(refresh_token)
    return nil unless payload && payload[:type] == 'refresh'
    
    # Generate new access token
    new_payload = { account_id: payload[:account_id] }
    encode(new_payload)
  rescue => e
    Rails.logger.error "Refresh token error: #{e.message}"
    nil
  end
end 