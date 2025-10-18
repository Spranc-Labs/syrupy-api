class AddDiscardedAtToResourceContents < ActiveRecord::Migration[7.1]
  def change
    add_column :resource_contents, :discarded_at, :datetime
    add_index :resource_contents, :discarded_at
  end
end
