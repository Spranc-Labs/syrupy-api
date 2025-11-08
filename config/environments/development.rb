# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.logger = if ENV['CI'] == 'true'
                    # Log to file
                    ActiveSupport::Logger.new(Rails.root.join('log', "#{Rails.env}.log"))
                  else
                    # Log to stdout
                    ActiveSupport::Logger.new($stdout)
                                         .tap { |logger| logger.formatter = Logger::Formatter.new }
                                         .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
                  end

  ActiveRecord::Base.logger = config.logger

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = ENV['EAGER_LOAD_CLASSES'] != 'true'
  config.eager_load = ENV['EAGER_LOAD_CLASSES'] == 'true'

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  config.action_controller.perform_caching = false
  config.cache_store = :solid_cache_store

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  config.assume_ssl = false
  config.force_ssl = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  # Allow requests from Docker containers and localhost
  config.hosts << 'api'
  config.hosts << 'localhost'
  config.hosts << '127.0.0.1'
  config.hosts << 'api:3000'
  config.hosts << 'localhost:3000'
  config.hosts << '127.0.0.1:3000'
end
