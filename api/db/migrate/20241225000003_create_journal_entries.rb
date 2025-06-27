class CreateJournalEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :journal_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.integer :mood_rating
      t.timestamps
      t.datetime :discarded_at
      t.index :discarded_at
      t.index [:user_id, :created_at]
      t.index :mood_rating
    end
  end
end 