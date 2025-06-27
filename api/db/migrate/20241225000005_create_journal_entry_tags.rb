class CreateJournalEntryTags < ActiveRecord::Migration[7.1]
  def change
    create_table :journal_entry_tags do |t|
      t.references :journal_entry, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
      t.index [:journal_entry_id, :tag_id], unique: true
    end
  end
end 