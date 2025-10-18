class AddKindToTags < ActiveRecord::Migration[7.1]
  def change
    add_column :tags, :kind, :string, null: false, default: 'user'
    add_index :tags, :kind
    
    # Add a unique index on name and kind to allow same tag names for different kinds
    remove_index :tags, :name if index_exists?(:tags, :name)
    add_index :tags, [:name, :kind], unique: true
  end
end
