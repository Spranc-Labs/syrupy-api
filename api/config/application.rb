require_relative "boot"
require_relative "../app/services/credentials"

require "rails"

%w[
  active_record/railtie
  active_storage/engine
  action_controller/railtie
  action_view/railtie
  action_mailer/railtie
  active_job/railtie
  action_cable/engine
  action_text/engine
  rails/test_unit/railtie
].each do |railtie|
  require railtie
rescue LoadError
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SyrupyApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    Dir[Rails.root.join("app/middleware/*.{rb}")].each { |file| require file }

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.autoload_paths += [
      "#{config.root}/app/blueprints",
      "#{config.root}/app/middleware",
      "#{config.root}/app/policies",
      "#{config.root}/app/services",
    ]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "UTC"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.middleware.use ActionDispatch::Cookies
    # We are not setting this value in the respective environment config file
    # because we need the value to be defined here.
    domain = Rails.env.development? ? nil : ".syrupy.com" # nil allows localhost access
    config.cookie_domain = domain
    config.session_store(
      :cookie_store,
      key: "_syrupy_session" + (Rails.env.development? ? "_dev" : ""),
      domain: config.cookie_domain,
      same_site: :lax,
    )
    config.middleware.use config.session_store, config.session_options

    # Needed for good_job dashboard
    config.middleware.use Rack::MethodOverride
    config.middleware.use ActionDispatch::Flash

    config.active_job.queue_adapter = :good_job

    # We don't need the built-in active storage routes.
    config.active_storage.draw_routes = false

    # rubocop:disable Layout/LineLength
    config.active_record.encryption.primary_key = [
      # If old_primary_key is set, we must be rotating encryption keys.
      Credentials.get(:active_record_encryption, :old_primary_key),
      Credentials.get(:active_record_encryption, :primary_key),
    ].compact

    config.active_record.encryption.deterministic_key = Credentials.get(:active_record_encryption, :deterministic_key)
    config.active_record.encryption.key_derivation_salt = Credentials.get(:active_record_encryption, :key_derivation_salt)
    # rubocop:enable Layout/LineLength

    # Needed so that the batch loader cache is cleared between requests
    config.middleware.use BatchLoader::Middleware

    # Need to add this explicitly because otherwise rodauth runs first,
    # and we want to throttle BEFORE hitting rodauth.
    config.middleware.use Rack::Attack

    config.lograge.enabled = true
    config.lograge.base_controller_class = ["ActionController::API", "ActionController::Base"]
    config.lograge.custom_options = lambda do |event|
      result = {
        ip: event.payload[:ip],
        user_id: event.payload[:user_id],
        user_name: event.payload[:user_name],
      }

      if event.payload[:status].is_a?(Integer) && event.payload[:status] >= 400
        result[:response_body] = event.payload[:response_body]
      end

      result
    end
  end
end 