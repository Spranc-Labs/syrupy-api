# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    association :account
    first_name { 'John' }
    last_name { 'Doe' }
    sequence(:email) { |n| "user#{n}@example.com" }
  end
end
