# frozen_string_literal: true

class ApplicationBlueprint < Blueprinter::Base
  class << self
    # Use this method to render an object with nested associations, eg;
    # JournalEntryBlueprint.render_with_associations(entry, { user: {} })
    def render_with_associations(object, associations, **)
      blueprint_name = object.respond_to?(:model) ? object.model.name : object.class.name
      blueprint_class = "#{blueprint_name}Blueprint".constantize
      blueprint_class.render_as_hash(object, include: associations, **)
    end

    def include_association?(options, association_name)
      return true if options.dig(:include)&.include?(association_name)

      # Recursive search for nested associations
      return options[:include].is_a?(Hash) && options[:include].any? do |key, value|
        include_association?({ include: value }, association_name)
      end
    end
  end
end 