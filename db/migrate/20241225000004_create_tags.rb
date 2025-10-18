class CreateTags < ActiveRecord::Migration[7.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.string :color, default: "#6366f1"
      t.timestamps
      t.datetime :discarded_at
      t.index :name, unique: true
      t.index :discarded_at
    end
  end
end 