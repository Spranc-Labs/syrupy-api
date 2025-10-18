class CreateJournalLabelAnalyses < ActiveRecord::Migration[7.1]
  def change
    create_table :journal_label_analyses do |t|
      t.references :journal_entry, null: false, foreign_key: true, index: true
      t.string :model_name, null: false
      t.string :model_version, null: false
      t.jsonb :payload, null: false, default: {}
      t.integer :run_ms
      t.datetime :analyzed_at, null: false, precision: 6
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :journal_label_analyses, :analyzed_at
    add_index :journal_label_analyses, :discarded_at
  end
end 