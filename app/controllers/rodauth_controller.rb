# frozen_string_literal: true

# Used by Rodauth for rendering views, CSRF protection, and running any
# registered action callbacks and rescue_from handlers
class RodauthController < ApplicationController
  def current_account
    rodauth(:main).rails_account
  end

  def current_user
    current_account&.user
  end
end 