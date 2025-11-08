# frozen_string_literal: true

class CreateCollections < ActiveRecord::Migration[7.0]
  def change
    create_table :collections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :icon
      t.string :color, default: "#6366f1"
      t.text :description
      t.integer :position, default: 0
      t.boolean :is_default, default: false
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :collections, [:user_id, :name], unique: true, where: "discarded_at IS NULL"
    add_index :collections, [:user_id, :is_default]
    add_index :collections, :position
  end
end
