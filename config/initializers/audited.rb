# frozen_string_literal: true

Audited.config do |config|
  # Use JSON serialization instead of YAML to avoid TimeWithZone serialization issues
  config.audit_class.serialize :audited_changes, coder: JSON
end
