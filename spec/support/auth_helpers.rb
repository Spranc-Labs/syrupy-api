# frozen_string_literal: true

module AuthHelpers
  def auth_headers_for(user)
    token = JwtService.encode(account_id: user.account.id, type: 'access')
    { 'Authorization' => "Bearer #{token}", 'Host' => 'api' }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
