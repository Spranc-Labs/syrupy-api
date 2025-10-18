class RenameModelNameToAnalysisModel < ActiveRecord::Migration[7.1]
  def change
    rename_column :emotion_label_analyses, :model_name, :analysis_model
    rename_column :journal_label_analyses, :model_name, :analysis_model
  end
end
