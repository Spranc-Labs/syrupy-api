class JournalLabelerService
  include HTTParty

  default_timeout 30
  
  def self.base_uri
    ENV.fetch('JOURNAL_LABELER_SERVICE_URL', 'http://localhost:8001')
  end
  
  class << self
    def analyze_journal_entry(title:, content:)
      Rails.logger.info "Analyzing journal entry with journal labeler service"
      
      response = post("#{base_uri}/analyze", 
        body: {
          title: title,
          content: content
        }.to_json,
        headers: {
          'Content-Type' => 'application/json'
        }
      )
      
      if response.success?
        parse_analysis_response(response.parsed_response)
      else
        Rails.logger.error "Journal labeler service error: #{response.code} - #{response.message}"
        fallback_analysis(title: title, content: content)
      end
    rescue StandardError => e
      Rails.logger.error "Failed to connect to journal labeler service: #{e.message}"
      fallback_analysis(title: title, content: content)
    end

    def predict_mood(title:, content:)
      Rails.logger.info "Predicting mood with journal labeler service"
      
      response = post("#{base_uri}/predict_mood", 
        body: {
          title: title,
          content: content
        }.to_json,
        headers: {
          'Content-Type' => 'application/json'
        }
      )
      
      if response.success?
        parse_mood_response(response.parsed_response)
      else
        Rails.logger.error "Mood prediction error: #{response.code} - #{response.message}"
        fallback_mood
      end
    rescue StandardError => e
      Rails.logger.error "Failed to predict mood: #{e.message}"
      fallback_mood
    end

    def predict_category(title:, content:)
      Rails.logger.info "Predicting category with journal labeler service"
      
      response = post("#{base_uri}/predict_category", 
        body: {
          title: title,
          content: content
        }.to_json,
        headers: {
          'Content-Type' => 'application/json'
        }
      )
      
      if response.success?
        parse_category_response(response.parsed_response)
      else
        Rails.logger.error "Category prediction error: #{response.code} - #{response.message}"
        fallback_category
      end
    rescue StandardError => e
      Rails.logger.error "Failed to predict category: #{e.message}"
      fallback_category
    end

    def health_check
      Rails.logger.info "Checking AI service health at: #{base_uri}/health"
      response = get("#{base_uri}/health")
      Rails.logger.info "Health check response: #{response.code} - #{response.parsed_response}"
      response.success? && response.parsed_response['status'] == 'healthy'
    rescue StandardError => e
      Rails.logger.error "Health check failed: #{e.message}"
      false
    end

    def available_categories
      response = get("#{base_uri}/categories")
      if response.success?
        response.parsed_response['categories'] || []
      else
        default_categories
      end
    rescue StandardError
      default_categories
    end

    private

    def parse_analysis_response(response)
      mood = response['mood'] || {}
      category = response['category'] || {}
      
      {
        mood_score: mood['mood_score']&.to_f || 0.0,
        mood_label: mood['mood_label'] || 'neutral',
        mood_confidence: mood['confidence']&.to_f || 0.5,
        emotions: mood['emotions'] || {},
        category: category['category'] || 'daily_life',
        category_confidence: category['confidence']&.to_f || 0.3,
        subcategories: category['subcategories'] || [],
        processing_time_ms: response['processing_time_ms']&.to_f || 0.0
      }
    end

    def parse_mood_response(response)
      {
        mood_score: response['mood_score']&.to_f || 0.0,
        mood_label: response['mood_label'] || 'neutral',
        confidence: response['confidence']&.to_f || 0.5,
        emotions: response['emotions'] || {}
      }
    end

    def parse_category_response(response)
      {
        category: response['category'] || 'daily_life',
        confidence: response['confidence']&.to_f || 0.3,
        subcategories: response['subcategories'] || []
      }
    end

    def fallback_analysis(title:, content:)
      Rails.logger.warn "Using fallback analysis due to journal labeler service unavailability"
      
      # Simple keyword-based fallback
      text = "#{title} #{content}".downcase
      
      mood_score = calculate_simple_mood(text)
      category = determine_simple_category(text)
      
      {
        mood_score: mood_score,
        mood_label: mood_score_to_label(mood_score),
        mood_confidence: 0.3,
        emotions: { 'neutral' => 1.0 },
        category: category,
        category_confidence: 0.2,
        subcategories: [],
        processing_time_ms: 0.0
      }
    end

    def fallback_mood
      {
        mood_score: 0.0,
        mood_label: 'neutral',
        confidence: 0.3,
        emotions: { 'neutral' => 1.0 }
      }
    end

    def fallback_category
      {
        category: 'daily_life',
        confidence: 0.2,
        subcategories: []
      }
    end

    def calculate_simple_mood(text)
      positive_words = %w[happy joy love great amazing wonderful excited grateful good excellent fantastic]
      negative_words = %w[sad angry frustrated disappointed terrible awful hate worried anxious depressed]
      
      positive_count = positive_words.count { |word| text.include?(word) }
      negative_count = negative_words.count { |word| text.include?(word) }
      
      if positive_count > negative_count
        0.3 + (positive_count - negative_count) * 0.1
      elsif negative_count > positive_count
        -0.3 - (negative_count - positive_count) * 0.1
      else
        0.0
      end.clamp(-1.0, 1.0)
    end

    def determine_simple_category(text)
      category_keywords = {
        'work_career' => %w[work job career office meeting project business],
        'relationships' => %w[family friend love relationship partner spouse],
        'health_wellness' => %w[health fitness exercise gym workout medical doctor],
        'travel_adventure' => %w[travel trip vacation adventure explore journey],
        'emotions_feelings' => %w[feel feeling emotion mood happy sad angry],
        'personal_growth' => %w[goal learn growth improve development self],
        'hobbies_interests' => %w[hobby art music reading game creative],
        'daily_life' => %w[day today routine morning evening home]
      }
      
      scores = category_keywords.map do |category, keywords|
        score = keywords.count { |keyword| text.include?(keyword) }
        [category, score]
      end
      
      top_category = scores.max_by(&:last)
      top_category&.last&.positive? ? top_category.first : 'daily_life'
    end

    def mood_score_to_label(score)
      case score
      when 0.4..1.0 then 'very positive'
      when 0.1...0.4 then 'positive'
      when -0.1..0.1 then 'neutral'
      when -0.4...-0.1 then 'negative'
      else 'very negative'
      end
    end

    def default_categories
      %w[
        personal_growth relationships work_career health_wellness travel_adventure
        daily_life emotions_feelings hobbies_interests spirituality challenges_struggles
      ]
    end
  end
end 