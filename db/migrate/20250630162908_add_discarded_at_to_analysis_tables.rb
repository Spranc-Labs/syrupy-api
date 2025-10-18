class AddDiscardedAtToAnalysisTables < ActiveRecord::Migration[7.1]
  def change
    # All tables already have discarded_at columns and indexes from their create migrations:
    # - emotion_logs: CreateEmotionLogs (20250630162906)
    # - emotion_label_analyses: CreateEmotionLabelAnalyses (20250630162904)
    # - journal_label_analyses: CreateJournalLabelAnalyses (20250630162905)
    # This migration is a no-op to maintain migration history
  end
end 