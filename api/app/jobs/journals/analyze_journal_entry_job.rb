# frozen_string_literal: true

class AnalyzeJournalEntryJob < ApplicationJob
  queue_as :default

  retry_on JournalAnalysisApiClient::AnalysisError,
           wait: :exponentially_longer,
           attempts: 3

  def perform(journal_entry_id)
    journal_entry = JournalEntry.find_by(id: journal_entry_id)
    return unless journal_entry&.persisted?

    Rails.logger.info "Starting analysis for journal entry #{journal_entry.id}"

    analyze_with_journal_api(journal_entry)

    Rails.logger.info "Completed analysis for journal entry #{journal_entry.id}"
  rescue JournalAnalysisApiClient::TimeoutError => e
    Rails.logger.warn "Analysis timeout for entry #{journal_entry.id}: #{e.message}"
    # Don't retry on timeout
  rescue StandardError => e
    Rails.logger.error "Failed to analyze entry #{journal_entry.id}: #{e.message}"
    raise # Re-raise to trigger retry logic
  end

  private

  def analyze_with_journal_api(journal_entry)
    # Call the dedicated journal-analysis-api
    analysis_response = JournalAnalysisApiClient.analyze(
      title: journal_entry.title,
      content: journal_entry.content
    )

    # Extract mood and category data
    mood_data = analysis_response['mood'] || {}
    category_data = analysis_response['category'] || {}
    analysis_response['processing_time_ms'] || 0

    # Create emotion analysis record
    emotion_analysis = journal_entry.emotion_label_analyses.create!(
      analysis_model: 'journal-analysis-api',
      model_version: mood_data['version'] || '1.0',
      payload: mood_data.except('version', 'label'),
      top_emotion: mood_data['label'],
      analyzed_at: Time.current
    )

    # Create category analysis record
    category_analysis = journal_entry.journal_label_analyses.create!(
      analysis_model: 'journal-analysis-api',
      model_version: category_data['version'] || '1.0',
      payload: category_data.except('version', 'label'),
      label: category_data['label'],
      analyzed_at: Time.current
    )

    # Update journal entry with latest analyses
    journal_entry.update!(
      emotion_label_analysis: emotion_analysis,
      journal_label_analysis: category_analysis
    )

    # Create system tags from analysis
    create_system_tags(journal_entry, category_data)
  end

  def create_system_tags(journal_entry, category_data)
    return unless category_data.present?

    category = category_data['label']
    return unless category.present?

    tag = Tag.find_or_create_by(
      name: category.downcase,
      kind: 'system'
    ) do |new_tag|
      new_tag.color = category_color(category)
    end

    journal_entry.tags << tag unless journal_entry.tags.include?(tag)
  end

  def category_color(category)
    color_map = {
      'personal_growth' => '#10b981',
      'relationships' => '#f59e0b',
      'work_career' => '#3b82f6',
      'health_wellness' => '#ef4444',
      'travel_adventure' => '#8b5cf6',
      'daily_life' => '#6b7280',
      'emotions_feelings' => '#ec4899',
      'hobbies_interests' => '#f97316',
      'spirituality' => '#06b6d4',
      'challenges_struggles' => '#7c3aed'
    }
    color_map[category.to_s.downcase] || '#6b7280'
  end
end
