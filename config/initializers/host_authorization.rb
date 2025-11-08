# frozen_string_literal: true

# Disable host authorization in test environment
Rails.application.config.hosts.clear if Rails.env.test?
