# frozen_string_literal: true

FactoryBot.define do
  factory :collection do
    association :user
    sequence(:name) { |n| "Collection #{n}" }
    color { '#6366f1' }
    description { 'A sample collection' }
    position { 0 }
    is_default { false }

    trait :default do
      is_default { true }
    end

    trait :with_bookmarks do
      after(:create) do |collection|
        create_list(:bookmark, 3, collection: collection, user: collection.user)
      end
    end
  end
end
