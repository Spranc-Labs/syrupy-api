class JournalEntry < ApplicationRecord
  audited

  belongs_to :user
  has_many :journal_entry_tags, dependent: :destroy
  has_many :tags, through: :journal_entry_tags

  validates :title, presence: true
  validates :content, presence: true
  validates :mood_rating, inclusion: { in: 1..10 }, allow_blank: true

  # Journal labeling callbacks
  after_create :analyze_with_ai_async
  after_update :analyze_with_ai_async, if: :should_reanalyze?

  # Serialization for AI emotions data
  serialize :ai_emotions, coder: JSON

  scope :filter_by_text, ->(text) {
    if text.present?
      search_by_keywords(text)
    end
  }

  scope :search_by_keywords, ->(query) {
    return all if query.blank?
    
    # Split query into individual terms and clean them
    terms = query.downcase.split(/\s+/).map(&:strip).reject(&:blank?)
    return all if terms.empty?
    
    # Build search conditions for each term
    conditions = terms.map do |term|
      sanitized_term = "%#{sanitize_sql_like(term)}%"
      "(title ILIKE ? OR content ILIKE ?)"
    end.join(" AND ")
    
    # Flatten the parameters array
    params = terms.flat_map do |term|
      sanitized_term = "%#{sanitize_sql_like(term)}%"
      [sanitized_term, sanitized_term]
    end
    
    where(conditions, *params)
      .select("journal_entries.*")
      .select(search_rank_sql(terms))
      .order("search_rank DESC, created_at DESC")
  }

  scope :by_mood_range, ->(min, max) {
    where(mood_rating: min..max) if min.present? && max.present?
  }

  scope :by_ai_mood_range, ->(min, max) {
    where(ai_mood_score: min..max) if min.present? && max.present?
  }

  scope :by_ai_category, ->(category) {
    where(ai_category: category) if category.present?
  }

  scope :by_date_range, ->(start_date, end_date) {
    where(created_at: start_date..end_date) if start_date.present? && end_date.present?
  }

  scope :recent, -> { order(created_at: :desc) }

  scope :ai_analyzed, -> { where.not(ai_analyzed_at: nil) }

  def formatted_date
    created_at.strftime("%B %d, %Y")
  end

  def word_count
    content.split.size
  end

  def ai_analyzed?
    ai_analyzed_at.present?
  end

  def analyze_with_ai!
    Rails.logger.info "Analyzing journal entry #{id} with journal labeler service"
    
    analysis = JournalLabelerService.analyze_journal_entry(
      title: title,
      content: content
    )
    
    update!(
      ai_mood_score: analysis[:mood_score],
      ai_mood_label: analysis[:mood_label],
      ai_category: analysis[:category],
      ai_emotions: analysis[:emotions],
      ai_processing_time_ms: analysis[:processing_time_ms],
      ai_analyzed_at: Time.current
    )
    
    Rails.logger.info "Journal labeling completed for journal entry #{id}"
    analysis
  rescue StandardError => e
    Rails.logger.error "Failed to analyze journal entry #{id}: #{e.message}"
    nil
  end

  def ai_mood_emoji
    case ai_mood_label
    when 'very positive' then '😄'
    when 'positive' then '😊'
    when 'neutral' then '😐'
    when 'negative' then '😔'
    when 'very negative' then '😢'
    else '❓'
    end
  end

  def ai_category_display
    ai_category&.humanize || 'Unknown'
  end

  def dominant_emotion
    return nil unless ai_emotions.is_a?(Hash) && ai_emotions.any?
    
    ai_emotions.max_by { |_, score| score }&.first
  end

  def dominant_emotion_emoji
    emotion_emojis = {
      'joy' => '😄', 'happiness' => '😊', 'love' => '❤️',
      'sadness' => '😢', 'anger' => '😠', 'fear' => '😨',
      'surprise' => '😲', 'disgust' => '🤢', 'anticipation' => '🤔',
      'trust' => '🤗', 'optimism' => '🌟', 'pessimism' => '😞'
    }
    
    emotion = dominant_emotion
    emotion_emojis[emotion] || '❓'
  end

  private

  def should_reanalyze?
    # Reanalyze if title or content changed
    saved_change_to_title? || saved_change_to_content?
  end

  def analyze_with_ai_async
    # Use background job for AI analysis to avoid blocking the request
    AnalyzeJournalEntryJob.perform_later(self)
  end

  def self.search_rank_sql(terms)
    # Calculate relevance score based on:
    # - Title exact matches (highest weight)
    # - Title partial matches (high weight)  
    # - Content matches (medium weight)
    # - Tag matches (medium weight)
    rank_parts = terms.map do |term|
      sanitized_term = sanitize_sql_like(term)
      escaped_term = "'%#{sanitized_term}%'"
      
      <<~SQL
        (
          CASE WHEN LOWER(title) = LOWER('#{sanitized_term}') THEN 100
               WHEN LOWER(title) ILIKE #{escaped_term} THEN 50
               ELSE 0
          END +
          (LENGTH(content) - LENGTH(REPLACE(LOWER(content), LOWER('#{sanitized_term}'), ''))) / LENGTH('#{sanitized_term}') * 10 +
          (
            SELECT COALESCE(COUNT(*) * 25, 0)
            FROM journal_entry_tags jet
            JOIN tags t ON jet.tag_id = t.id
            WHERE jet.journal_entry_id = journal_entries.id
            AND LOWER(t.name) ILIKE #{escaped_term}
          )
        )
      SQL
    end
    
    "(#{rank_parts.join(' + ')}) AS search_rank"
  end
end 