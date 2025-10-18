# frozen_string_literal: true

# Disable host authorization in test environment
if Rails.env.test?
  Rails.application.config.hosts.clear
end
