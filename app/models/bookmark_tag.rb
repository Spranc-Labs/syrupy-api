# frozen_string_literal: true

class BookmarkTag < ApplicationRecord
  include Discard::Model

  # Associations
  belongs_to :bookmark
  belongs_to :tag

  # Validations
  validates :bookmark_id, uniqueness: { scope: :tag_id }
end
