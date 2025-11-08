# frozen_string_literal: true

FactoryBot.define do
  factory :bookmark do
    association :user
    association :collection
    sequence(:url) { |n| "https://example.com/page-#{n}" }
    sequence(:title) { |n| "Bookmark #{n}" }
  end
end
