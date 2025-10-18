class UpdateJournalEntriesForNewAnalysisModel < ActiveRecord::Migration[7.1]
  def change
    # Add references to analysis tables
    add_reference :journal_entries, :emotion_label_analysis, 
                  null: true, 
                  foreign_key: { on_delete: :nullify }, 
                  index: true

    add_reference :journal_entries, :journal_label_analysis, 
                  null: true, 
                  foreign_key: { on_delete: :nullify }, 
                  index: true

    # Remove obsolete AI and mood columns if they exist
    if column_exists?(:journal_entries, :ai_mood_score)
      remove_index :journal_entries, :ai_category if index_exists?(:journal_entries, :ai_category)
      remove_index :journal_entries, :ai_mood_label if index_exists?(:journal_entries, :ai_mood_label)
      
      remove_column :journal_entries, :ai_mood_score, :decimal
      remove_column :journal_entries, :ai_mood_label, :string
      remove_column :journal_entries, :ai_category, :string
      remove_column :journal_entries, :ai_emotions, :text
      remove_column :journal_entries, :ai_processing_time_ms, :decimal
      remove_column :journal_entries, :ai_analyzed_at, :timestamp
    end

    # Remove mood columns if they exist
    remove_column :journal_entries, :mood_rating, :integer if column_exists?(:journal_entries, :mood_rating)
    remove_column :journal_entries, :mood, :string if column_exists?(:journal_entries, :mood)
  end
end 