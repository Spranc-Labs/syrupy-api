# See https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html
# We use this to set some request-specific attributes that we want to be available globally.
# This automatically resets the attributes at the end of the request.
class Current < ActiveSupport::CurrentAttributes
  attribute :account, :user
  attribute :request_id, :user_agent, :ip_address

  def user=(user)
    super
    self.account = user&.account
  end
end 