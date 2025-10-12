class ResourceBlueprint < Blueprinter::Base
  identifier :id

  fields :url, :title, :status, :scraped_at, :created_at, :updated_at, :metadata

  field :domain do |resource|
    resource.domain
  end

  field :has_content do |resource|
    resource.has_content?
  end

  field :rss_feed_url do |resource|
    resource.rss_feed_url
  end

  association :tags, blueprint: TagBlueprint

  view :with_content do
    association :resource_content, blueprint: ResourceContentBlueprint
  end
end 