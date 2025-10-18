# frozen_string_literal: true

# Client for communicating with journal-analysis-api service
# Handles mood and category predictions for journal entries
class JournalAnalysisApiClient
  BASE_URL = ENV.fetch('JOURNAL_ANALYSIS_API_URL', 'http://localhost:8001')
  REQUEST_TIMEOUT = 30
  OPEN_TIMEOUT = 10

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

  # Build Faraday connection with middleware stack
  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      # Request middleware
      f.request :json                          # Encode request body as JSON
      f.request :retry,                        # Retry failed requests with backoff
                max: 3,
                interval: 0.5,
                backoff_factor: 2,
                retry_statuses: [408, 429, 500, 502, 503, 504],
                methods: [:post]

      # Response middleware
      f.response :json,                        # Parse response body as JSON
                 content_type: /\bjson$/,
                 parser_options: { symbolize_names: false }
      f.response :logger, Rails.logger,        # Log requests/responses
                 { headers: true, bodies: false } do |logger|
        logger.filter(/(title|content)/, '[FILTERED]')
      end
      f.response :raise_error                  # Raise errors for 4xx/5xx responses

      # HTTP adapter
      f.adapter Faraday.default_adapter
    end
  end

  def make_request(endpoint, payload)
    response = connection.post(endpoint) do |req|
      req.body = payload
      req.options.timeout = REQUEST_TIMEOUT        # Request timeout
      req.options.open_timeout = OPEN_TIMEOUT      # Connection timeout
    end

    # Response body already parsed by json middleware
    response.body.with_indifferent_access
  rescue Faraday::TimeoutError => e
    Rails.logger.error("Journal Analysis API timeout: #{e.message}")
    raise TimeoutError, "Analysis service request timeout after #{REQUEST_TIMEOUT}s"
  rescue Faraday::ConnectionFailed => e
    Rails.logger.error("Journal Analysis API connection failed: #{e.message}")
    raise ConnectionError, "Failed to connect to analysis service: #{e.message}"
  rescue Faraday::ServerError => e
    Rails.logger.error("Journal Analysis API server error: #{e.response[:status]} - #{e.message}")
    raise ConnectionError, "Analysis service unavailable (HTTP #{e.response[:status]})"
  rescue Faraday::ClientError => e
    # 4xx errors
    status = e.response[:status]
    body = e.response[:body]
    Rails.logger.error("Journal Analysis API client error: #{status} - #{body}")
    raise AnalysisError, "Analysis failed: HTTP #{status} - #{body}"
  rescue Faraday::Error => e
    Rails.logger.error("Journal Analysis API error: #{e.message}")
    raise AnalysisError, "Analysis request failed: #{e.message}"
  end
end
