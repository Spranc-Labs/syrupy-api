class ResourceContent < ApplicationRecord
  belongs_to :resource

  validates :resource, presence: true, uniqueness: true
end 