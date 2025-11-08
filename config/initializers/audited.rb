# frozen_string_literal: true

# Only configure audited if the database and tables are set up
# This allows db:create and db:schema:load to run without errors
begin
  if ActiveRecord::Base.connection.table_exists?('audits')
    Audited.config do |config|
      # Use JSON serialization instead of YAML to avoid TimeWithZone serialization issues
      config.audit_class.serialize :audited_changes, coder: JSON
    end
  end
rescue ActiveRecord::NoDatabaseError
  # Database doesn't exist yet (e.g., during db:create)
  Rails.logger.debug 'Skipping audited configuration - database not ready'
end
