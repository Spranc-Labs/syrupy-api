class CreateGoals < ActiveRecord::Migration[7.1]
  def change
    create_table :goals do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :status, default: "active", null: false
      t.string :priority, default: "medium", null: false
      t.date :target_date
      t.timestamps
      t.datetime :discarded_at
    end

    add_index :goals, :discarded_at
    add_index :goals, :status
    add_index :goals, :priority
    add_index :goals, :target_date
  end
end 