# frozen_string_literal: true

class CollectionBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :icon, :color, :description, :position, :is_default, :created_at, :updated_at

  view :with_counts do
    field :bookmarks_count do |collection|
      collection.bookmarks.kept.count
    end
  end

  view :with_bookmarks do
    field :bookmarks_count do |collection|
      collection.bookmarks.kept.count
    end

    association :bookmarks, blueprint: BookmarkBlueprint, view: :compact do |collection|
      collection.bookmarks.kept.recent.limit(10)
    end
  end
end
