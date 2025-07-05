class AddDiscardedAtToAnalysisTables < ActiveRecord::Migration[7.1]
  def change
    add_column :emotion_logs, :discarded_at, :datetime
    add_column :emotion_label_analyses, :discarded_at, :datetime
    add_column :journal_label_analyses, :discarded_at, :datetime
    
    add_index :emotion_logs, :discarded_at
    add_index :emotion_label_analyses, :discarded_at
    add_index :journal_label_analyses, :discarded_at
  end
end 