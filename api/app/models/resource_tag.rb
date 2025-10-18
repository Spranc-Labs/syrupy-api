# frozen_string_literal: true

class ResourceTag < ApplicationRecord
  belongs_to :resource
  belongs_to :tag

  validates :resource, presence: true
  validates :tag, presence: true
  validates :resource_id, uniqueness: { scope: :tag_id }
end 