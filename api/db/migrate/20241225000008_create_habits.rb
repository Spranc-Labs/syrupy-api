class CreateHabits < ActiveRecord::Migration[7.1]
  def change
    create_table :habits do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :frequency, default: "daily", null: false
      t.boolean :active, default: true, null: false
      t.timestamps
      t.datetime :discarded_at
    end

    add_index :habits, :discarded_at
    add_index :habits, :frequency
    add_index :habits, :active
  end
end 