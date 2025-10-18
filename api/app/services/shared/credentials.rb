# frozen_string_literal: true

class Credentials
  class << self
    # Method to fetch configuration with support for ENV variables and credentials
    # E.g. Credentials.get(:active_record_encryption, :primary_key)
    # Will first look for ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
    # If not found, will look for Rails.application.credentials.dig(:active_record_encryption, :primary_key)
    def get(*keys)
      # Construct an ENV key from the keys array for nested access
      env_key = keys.map(&:to_s).join("_").upcase
      env_value = ENV[env_key]

      # Return the ENV value if it exists
      return env_value if env_value.present?

      # Otherwise, dig through Rails credentials
      return Rails.application.credentials.dig(*keys)
    end
  end
end 