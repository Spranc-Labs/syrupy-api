# frozen_string_literal: true

class RodauthMain < Rodauth::Rails::Auth
  configure do
    # See the Rodauth documentation for the list of available config options:
    # http://rodauth.jeremyevans.net/documentation.html

    # List of basic authentication features
    enable :create_account, :login, :logout, :json

    # Accept only JSON requests for API
    only_json? true

    # Use path prefix for all routes
    prefix '/auth'

    # Specify the controller used for view rendering, CSRF, and callbacks
    rails_controller { RodauthController }

    # Store account status in an integer column without foreign key constraint
    account_status_column :status

    # Store password hash in a column instead of a separate table
    account_password_hash_column :password_hash

    # Change some default param keys for cleaner API
    login_param 'email'

    # Handle login and password confirmation fields on the client side
    require_password_confirmation? false

    # ==> Validation
    # Passwords shorter than 8 characters are considered weak
    password_minimum_length 8

    # ==> Session Management
    # Session key prefix
    session_key_prefix 'syrupy_'

    # ==> Email Configuration (for development)
    email_subject_prefix 'Syrupy: '

    # ==> Hooks
    # Validate custom fields in the create account form
    before_create_account do
      throw_error_status(422, 'First name', 'must be present') if param('first_name').blank?
      throw_error_status(422, 'Last name', 'must be present') if param('last_name').blank?
      throw_error_status(422, 'Email', 'must be present') if param('email').blank?
    end

    # Perform additional actions after the account is created
    after_create_account do
      # Create associated User record
      User.create!(
        account_id: account_id,
        first_name: param('first_name'),
        last_name: param('last_name'),
        email: param('email')
      )
    end

    # Auto-login after account creation for better UX
    create_account_autologin? true

    # ==> Redirects (for JSON API, these won't be used but good to have)
    login_redirect { '/' }
    logout_redirect { '/' }
  end
end
