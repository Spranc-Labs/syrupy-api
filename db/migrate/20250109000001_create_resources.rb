class CreateResources < ActiveRecord::Migration[7.0]
  def change
    create_table :resources do |t|
      t.references :user, null: false, foreign_key: true
      t.string :url, null: false
      t.string :title
      t.integer :status, default: 0
      t.datetime :scraped_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :resources, :url
    add_index :resources, :status
    add_index :resources, :metadata, using: :gin
  end
end 