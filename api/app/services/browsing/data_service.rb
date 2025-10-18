# frozen_string_literal: true

# Service for fetching browsing data from Sync-BE API
class BrowsingDataService
  include HTTParty
  base_uri ENV.fetch('HEYHO_SYNC_API_URL', 'http://localhost:3001')

  def self.fetch_browsing_data(user_email:, page: 1, per_page: 50)
    new.fetch_browsing_data(user_email: user_email, page: page, per_page: per_page)
  end

  def self.fetch_summary(user_email:)
    new.fetch_summary(user_email: user_email)
  end

  def fetch_browsing_data(user_email:, page: 1, per_page: 50)
    response = self.class.get(
      '/api/v1/browsing_data',
      query: {
        email: user_email,
        page: page,
        per_page: per_page
      },
      headers: auth_headers
    )

    handle_response(response)
  rescue StandardError => e
    Rails.logger.error "Error fetching browsing data: #{e.message}"
    error_result("Failed to fetch browsing data: #{e.message}")
  end

  def fetch_summary(user_email:)
    response = self.class.get(
      '/api/v1/browsing_data/summary',
      query: { email: user_email },
      headers: auth_headers
    )

    handle_response(response)
  rescue StandardError => e
    Rails.logger.error "Error fetching browsing summary: #{e.message}"
    error_result("Failed to fetch browsing summary: #{e.message}")
  end

  private

  def auth_headers
    {
      'X-Service-Token' => ENV.fetch('SERVICE_SECRET', ''),
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  def handle_response(response)
    case response.code
    when 200
      success_result(response.parsed_response)
    when 401
      error_result('Unauthorized: Invalid service credentials')
    when 404
      error_result('User not found in Sync-BE')
    when 422
      error_result(response.parsed_response['message'] || 'Validation error')
    else
      error_result("Unexpected error: #{response.code} - #{response.message}")
    end
  end

  def success_result(data)
    Result.new(success: true, data: data, errors: [])
  end

  def error_result(message)
    Result.new(success: false, data: nil, errors: [message])
  end

  # Result struct for consistent response format
  Result = Struct.new(:success, :data, :errors, keyword_init: true) do
    def success?
      success
    end

    def failure?
      !success
    end
  end
end
