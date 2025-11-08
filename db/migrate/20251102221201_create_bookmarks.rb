# frozen_string_literal: true

class CreateBookmarks < ActiveRecord::Migration[7.0]
  def change
    create_table :bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :collection, null: true, foreign_key: true
      t.string :url, null: false
      t.string :title
      t.text :description
      t.text :note
      t.string :status, default: "unsorted"
      t.datetime :saved_at, null: false
      t.datetime :read_at
      t.datetime :archived_at
      t.jsonb :metadata, default: {}
      t.string :source, default: "manual"
      t.string :heyho_page_visit_id
      t.datetime :discarded_at

      t.timestamps
    end

    # Note: user_id and collection_id indexes are automatically created by t.references
    add_index :bookmarks, :url
    add_index :bookmarks, :status
    add_index :bookmarks, :saved_at
    add_index :bookmarks, :source
    add_index :bookmarks, :metadata, using: :gin
  end
end
