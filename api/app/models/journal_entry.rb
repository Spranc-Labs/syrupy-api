class JournalEntry < ApplicationRecord
  audited

  belongs_to :user
  has_many :journal_entry_tags, dependent: :destroy
  has_many :tags, through: :journal_entry_tags

  validates :title, presence: true
  validates :content, presence: true
  validates :mood_rating, inclusion: { in: 1..10 }, allow_blank: true

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

  scope :by_date_range, ->(start_date, end_date) {
    where(created_at: start_date..end_date) if start_date.present? && end_date.present?
  }

  scope :recent, -> { order(created_at: :desc) }

  def formatted_date
    created_at.strftime("%B %d, %Y")
  end

  def word_count
    content.split.size
  end

  private

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