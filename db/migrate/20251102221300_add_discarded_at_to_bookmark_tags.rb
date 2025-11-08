# frozen_string_literal: true

class AddDiscardedAtToBookmarkTags < ActiveRecord::Migration[7.0]
  def change
    add_column :bookmark_tags, :discarded_at, :datetime
    add_index :bookmark_tags, :discarded_at
  end
end
