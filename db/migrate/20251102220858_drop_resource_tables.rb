# frozen_string_literal: true

class DropResourceTables < ActiveRecord::Migration[7.0]
  def up
    # Drop tables in reverse order of creation (due to foreign keys)
    drop_table :resource_tags, if_exists: true
    drop_table :resource_contents, if_exists: true
    drop_table :resources, if_exists: true
  end

  def down
    # Recreate tables if needed (for rollback)
    create_table :resources do |t|
      t.references :user, null: false, foreign_key: true
      t.string :url, null: false
      t.string :title
      t.integer :status, default: 0
      t.datetime :scraped_at
      t.jsonb :metadata, default: {}
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :resources, :url
    add_index :resources, :status
    add_index :resources, :metadata, using: :gin

    create_table :resource_contents do |t|
      t.references :resource, null: false, foreign_key: true, index: { unique: true }
      t.text :content
      t.datetime :discarded_at

      t.timestamps
    end

    create_table :resource_tags do |t|
      t.references :resource, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :resource_tags, [:resource_id, :tag_id], unique: true
  end
end
