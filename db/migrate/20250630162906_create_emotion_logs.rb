class CreateEmotionLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :emotion_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :emotion_label, null: false
      t.string :emoji
      t.text :note
      t.datetime :captured_at, null: false, precision: 6
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :emotion_logs, [:user_id, :captured_at]
    add_index :emotion_logs, :emotion_label
    add_index :emotion_logs, :captured_at
    add_index :emotion_logs, :discarded_at
  end
end 