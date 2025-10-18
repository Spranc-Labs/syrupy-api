class CreateMoodLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :mood_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :notes
      t.datetime :logged_at, null: false
      t.timestamps
      t.datetime :discarded_at
    end

    add_index :mood_logs, :discarded_at
    add_index :mood_logs, :rating
    add_index :mood_logs, :logged_at
    add_index :mood_logs, [:user_id, :logged_at]
  end
end 