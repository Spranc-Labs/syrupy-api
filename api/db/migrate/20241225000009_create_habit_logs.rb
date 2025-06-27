class CreateHabitLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :habit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :habit, null: false, foreign_key: true
      t.date :logged_date, null: false
      t.boolean :completed, default: false, null: false
      t.text :notes
      t.timestamps
      t.datetime :discarded_at
    end

    add_index :habit_logs, :discarded_at
    add_index :habit_logs, :logged_date
    add_index :habit_logs, :completed
    add_index :habit_logs, [:habit_id, :logged_date], unique: true
  end
end 