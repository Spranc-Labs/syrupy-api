class JournalEntry < ApplicationRecord
  audited

  belongs_to :user
  has_many :journal_entry_tags, dependent: :destroy
  has_many :tags, through: :journal_entry_tags

  # New analysis associations
  belongs_to :emotion_label_analysis,
             class_name:  "EmotionLabelAnalysis",
             optional:    true,
             foreign_key: :emotion_label_analysis_id

  belongs_to :journal_label_analysis,
             class_name:  "JournalLabelAnalysis",
             optional:    true,
             foreign_key: :journal_label_analysis_id

  has_many :emotion_label_analyses,  dependent: :destroy
  has_many :journal_label_analyses,  dependent: :destroy

  validates :title, presence: true
  validates :content, presence: true

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

  scope :analyzed, -> { where.not(emotion_label_analysis_id: nil, journal_label_analysis_id: nil) }

  def formatted_date
    created_at.strftime("%B %d, %Y")
  end

  def word_count
    content.split.size
  end

  def analyzed?
    emotion_label_analysis.present? && journal_label_analysis.present?
  end

  def analyze_with_ai!
    Rails.logger.info "Analyzing journal entry #{id} with journal labeler service"
    
    analysis = JournalLabelerService.analyze_journal_entry(
      title: title,
      content: content
    )
    
    # Create emotion analysis
    emotion_analysis = emotion_label_analyses.create!(
      analysis_model: 'emotion_classifier',
      model_version: '1.0',
      payload: analysis[:emotions] || {},
      top_emotion: analysis[:mood_label],
      run_ms: analysis[:processing_time_ms],
      analyzed_at: Time.current
    )
    
    # Create journal analysis  
    journal_analysis = journal_label_analyses.create!(
      analysis_model: 'category_classifier',
      model_version: '1.0', 
      payload: { category: analysis[:category] },
      run_ms: analysis[:processing_time_ms],
      analyzed_at: Time.current
    )
    
    # Link the latest analyses to this journal entry
    update!(
      emotion_label_analysis: emotion_analysis,
      journal_label_analysis: journal_analysis
    )
    
    # Create system tags from analysis
    create_system_tags_from_analysis(analysis)
    
    Rails.logger.info "Journal labeling completed for journal entry #{id}"
    analysis
  rescue StandardError => e
    Rails.logger.error "Failed to analyze journal entry #{id}: #{e.message}"
    nil
  end

  def current_category
    journal_label_analysis&.payload&.dig('category')
  end

  def category_display
    current_category&.humanize || 'Unknown'
  end

  def primary_emotion
    return nil unless emotion_label_analysis&.payload&.is_a?(Hash)
    
    emotion_label_analysis.payload.max_by { |_, score| score }&.first
  end

  def primary_emotion_emoji
    emotion_emojis = {
      'joy' => '😄', 'happiness' => '😊', 'love' => '❤️',
      'sadness' => '😢', 'anger' => '😠', 'fear' => '😨',
      'surprise' => '😲', 'disgust' => '🤢', 'anticipation' => '🤔',
      'trust' => '🤗', 'optimism' => '🌟', 'pessimism' => '😞'
    }
    
    emotion = primary_emotion
    emotion_emojis[emotion] || '❓'
  end

  private

  def should_reanalyze?
    # Reanalyze if title or content changed
    saved_change_to_title? || saved_change_to_content?
  end

  def analyze_with_ai_async
    # Use background job for AI analysis to avoid blocking the request
    AnalyzeJournalEntryJob.perform_later(id)
  end

  def create_system_tags_from_analysis(analysis)
    return unless analysis

    system_tags_to_create = []
    
    # Add category as a system tag
    if analysis[:category].present?
      system_tags_to_create << {
        name: analysis[:category].humanize.downcase,
        color: category_color(analysis[:category])
      }
    end
    
    # Add subcategories as system tags if they exist
    if analysis[:subcategories]&.any?
      analysis[:subcategories].each do |subcategory|
        system_tags_to_create << {
          name: subcategory.humanize.downcase,
          color: category_color(subcategory)
        }
      end
    end
    

    
    # Create or find system tags and associate them
    system_tags_to_create.uniq.each do |tag_data|
      tag = Tag.find_or_create_by(
        name: tag_data[:name],
        kind: 'system'
      ) do |new_tag|
        new_tag.color = tag_data[:color]
      end
      
      # Associate the tag with this journal entry if not already associated
      tags << tag unless tags.include?(tag)
    end
  end

  def category_color(category)
    color_map = {
      'personal_growth' => '#10b981',    # green
      'relationships' => '#f59e0b',      # amber
      'work_career' => '#3b82f6',        # blue
      'health_wellness' => '#ef4444',    # red
      'travel_adventure' => '#8b5cf6',   # violet
      'daily_life' => '#6b7280',         # gray
      'emotions_feelings' => '#ec4899',  # pink
      'hobbies_interests' => '#f97316',  # orange
      'spirituality' => '#06b6d4',       # cyan
      'challenges_struggles' => '#7c3aed' # purple
    }
    color_map[category] || '#6b7280'
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