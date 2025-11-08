# frozen_string_literal: true

class BookmarkBlueprint < Blueprinter::Base
  identifier :id

  fields :url, :title, :description, :note, :status, :source, :heyho_page_visit_id,
         :saved_at, :read_at, :archived_at, :created_at, :updated_at, :metadata

  field :domain do |bookmark|
    bookmark.extract_domain
  end

  association :collection, blueprint: CollectionBlueprint

  view :compact do
    fields :id, :url, :title, :status, :saved_at
    field :domain do |bookmark|
      bookmark.extract_domain
    end
  end

  view :with_tags do
    includes :domain
    association :tags, blueprint: TagBlueprint
  end

  view :detailed do
    includes :domain
    association :collection, blueprint: CollectionBlueprint
    association :tags, blueprint: TagBlueprint

    field :tags_count do |bookmark|
      bookmark.tags.count
    end
  end
end
