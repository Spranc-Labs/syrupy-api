# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    sequence(:email) { |n| "account#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    status { :verified }
  end
end
