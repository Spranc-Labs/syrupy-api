# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.3.3'

# Fix for stringio default gem version conflict
gem 'stringio', '~> 3.1.1'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.1.3.2'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 6.4.3'

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem 'bcrypt', '~> 3.1.7'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:windows, :jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem 'rack-cors', '~> 2.0.2'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: [:mri, :windows]
  # Rspec integration for Rails
  gem 'rspec-rails', '~> 6.1.0'
  # Rails specific rubocop rules
  gem 'rubocop-rails', require: false
  # Rspec specific rubocop rules
  gem 'rubocop-rspec', require: false
  # For better diffs in rspec
  gem 'super_diff'
  # For performance-related cops
  gem 'rubocop-performance', require: false
  # For checking for security issues
  gem 'brakeman'
  # For adding factories in tests
  gem 'factory_bot_rails'
  # For better assertions with JSON
  gem 'rspec-json_expectations'
  # For mocking time in tests
  gem 'timecop'
  # Adding this due to a security issue with 7.1.3
  gem 'actionpack', '> 7.1.3.1'
  # Dependency for actionpack to address a security issue.
  gem 'nokogiri', '~>1.18.4'
  # For mocking web requests in tests
  gem 'webmock'
  # For IDE integration
  gem 'ruby-lsp', require: false
end

group :test do
  # For testing for N+1 query problems
  gem 'n_plus_one_control'
end

group :development do
  # For sending emails in development without actually sending them
  gem 'letter_opener'
  # For viewing 'sent' emails in the browser
  gem 'letter_opener_web', '~> 2.0'

  # For convenient loading of .env file without having to
  # re-up containers when the file is changed
  gem 'dotenv'
end

# For authentication and registration (simplified approach)
# gem "rodauth-rails", "~> 1.13"
# gem "sequel", "~> 5.0" # Required by Rodauth

# For better logging of HTTP requests
gem 'httplog', '~> 1.6.3'

# For background jobs backed by postgres
gem 'good_job', '~> 3.28'
# Dependency for good job to address a security issue with 1.11
gem 'fugit', '>= 1.11.1'

# For caching, backed by postgres
gem 'solid_cache', '~> 0.4.2'

# For soft-deletion of records
gem 'discard', '~> 1.2'

# For keeping track of changes to records
gem 'audited'

# For pretty-printing objects
gem 'awesome_print'

# For authorization logic
gem 'pundit'

# For pagination
gem 'will_paginate', '~> 4.0', require: ['will_paginate', 'will_paginate/array']

# For serializing models
gem 'blueprinter'

# For bulk inserting records
gem 'activerecord-import'

# For HTTP requests with middleware support
gem 'faraday'

# For JWT token authentication
gem 'jwt'

# For generating random strings
gem 'securerandom'

# For grouping records by date in activerecord
gem 'groupdate'

# For creating fake data in tests, but also for mock data on prod
gem 'faker'

# For using postgres's advisory locks feature
gem 'with_advisory_lock'

# For monitoring postgres performance
gem 'pghero'
gem 'pg_query', '>= 2'
# Dependency for pg_query to address a security issue with 4.26.1#
gem 'google-protobuf', '>= 4.28.2'
# needed for PGHero performance dashboard
gem 'sass-rails', '>= 6'

# For throttling requests
gem 'rack-attack'

# For email validation
gem 'valid_email2'

# For avoiding N+1's
gem 'batch-loader'

# For better controller logs
gem 'lograge'

# For running data migrations (as opposed to schema migrations)
gem 'data_migrate'

# For handling CSV files
gem 'csv'

# Bumping this rails dependency to address a security issue in 3.0.11
gem 'rack', '~>3.0.14'
