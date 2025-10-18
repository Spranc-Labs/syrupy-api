# frozen_string_literal: true

class ResourceContent < ApplicationRecord
  belongs_to :resource

  validates :resource, presence: true, uniqueness: true
end 