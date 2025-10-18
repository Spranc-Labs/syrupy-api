class AddDiscardedAtToResourceTags < ActiveRecord::Migration[7.0]
  def change
    add_column :resource_tags, :discarded_at, :datetime
    add_index :resource_tags, :discarded_at
  end
end 