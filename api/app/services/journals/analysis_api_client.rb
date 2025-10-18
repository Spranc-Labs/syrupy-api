# frozen_string_literal: true

# Client for communicating with journal-analysis-api service
# Handles mood and category predictions for journal entries
class JournalAnalysisApiClient
  BASE_URL = ENV.fetch('JOURNAL_ANALYSIS_API_URL', 'http://localhost:8001')
  REQUEST_TIMEOUT = 30

  class AnalysisError < StandardError; end
  class ConnectionError < AnalysisError; end
  class TimeoutError < AnalysisError; end

  def self.analyze(title:, content:)
    new.analyze(title: title, content: content)
  end

  def self.predict_mood(title:, content:)
    new.predict_mood(title: title, content: content)
  end

  def self.predict_category(title:, content:)
    new.predict_category(title: title, content: content)
  end

  def analyze(title:, content:)
    make_request(
      '/analyze',
      { title: title, content: content }
    )
  end

  def predict_mood(title:, content:)
    make_request(
      '/predict_mood',
      { title: title, content: content }
    )
  end

  def predict_category(title:, content:)
    make_request(
      '/predict_category',
      { title: title, content: content }
    )
  end

  private

  def make_request(endpoint, payload)
    url = "#{BASE_URL}#{endpoint}"

    response = HTTParty.post(
      url,
      body: payload.to_json,
      headers: {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      },
      timeout: REQUEST_TIMEOUT
    )

    handle_response(response, endpoint)
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error("Journal Analysis API timeout: #{e.message}")
    raise TimeoutError, "Analysis service request timeout after #{REQUEST_TIMEOUT}s"
  rescue StandardError => e
    Rails.logger.error("Journal Analysis API error: #{e.message}")
    raise ConnectionError, "Failed to connect to analysis service: #{e.message}"
  end

  def handle_response(response, endpoint)
    case response.code
    when 200
      parse_response(response)
    when 408, 504
      raise TimeoutError, "Analysis service timeout (HTTP #{response.code})"
    when 500, 502, 503
      raise ConnectionError, "Analysis service unavailable (HTTP #{response.code})"
    else
      raise AnalysisError, "Analysis failed: HTTP #{response.code} - #{response.body}"
    end
  end

  def parse_response(response)
    JSON.parse(response.body).with_indifferent_access
  rescue JSON::ParserError => e
    Rails.logger.error("Invalid JSON response from analysis service: #{e.message}")
    raise AnalysisError, "Invalid response format from analysis service"
  end
end
