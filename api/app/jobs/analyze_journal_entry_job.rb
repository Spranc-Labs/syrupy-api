class AnalyzeJournalEntryJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(journal_entry)
    return unless journal_entry.persisted?
    
    Rails.logger.info "Starting AI analysis for journal entry #{journal_entry.id}"
    
    # Check if AI service is available
    unless AiInsightsService.health_check
      Rails.logger.warn "AI insights service is not available, skipping analysis for entry #{journal_entry.id}"
      return
    end
    
    # Perform the analysis
    journal_entry.analyze_with_ai!
    
    Rails.logger.info "Completed AI analysis for journal entry #{journal_entry.id}"
  rescue StandardError => e
    Rails.logger.error "Failed to analyze journal entry #{journal_entry.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise # Re-raise to trigger retry logic
  end
end 