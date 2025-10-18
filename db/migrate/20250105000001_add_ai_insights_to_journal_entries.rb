class AddAiInsightsToJournalEntries < ActiveRecord::Migration[7.1]
  def change
    add_column :journal_entries, :ai_mood_score, :decimal, precision: 5, scale: 3
    add_column :journal_entries, :ai_mood_label, :string
    add_column :journal_entries, :ai_category, :string
    add_column :journal_entries, :ai_emotions, :text
    add_column :journal_entries, :ai_processing_time_ms, :decimal, precision: 8, scale: 2
    add_column :journal_entries, :ai_analyzed_at, :timestamp
    
    add_index :journal_entries, :ai_category
    add_index :journal_entries, :ai_mood_label
  end
end 