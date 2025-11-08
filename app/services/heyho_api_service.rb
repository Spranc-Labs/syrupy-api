# frozen_string_literal: true

require 'net/http'
require 'json'

# Service for interacting with HeyHo Sync-BE API
class HeyhoApiService
  class << self
    # Exchange authorization code for HeyHo user information
    def exchange_authorization_code(code:, redirect_uri:)
      uri = URI("#{heyho_base_url}/api/v1/oauth/token")

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = {
        code: code,
        client_id: 'syrupy',
        redirect_uri: redirect_uri
      }.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      parse_token_response(response)
    rescue StandardError => e
      Rails.logger.error("HeyHo API error: #{e.message}")
      {
        success: false,
        error: "Failed to connect to HeyHo: #{e.message}"
      }
    end

    # Fetch browsing insights for a HeyHo user
    def fetch_browsing_insights(heyho_user_id:, start_date: nil, end_date: nil)
      uri = URI("#{heyho_base_url}/api/v1/browsing_data")
      params = { user_id: heyho_user_id }
      params[:start_date] = start_date.to_s if start_date
      params[:end_date] = end_date.to_s if end_date
      uri.query = URI.encode_www_form(params)

      request = Net::HTTP::Get.new(uri)
      request['Content-Type'] = 'application/json'
      request['X-Service-Secret'] = service_secret

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        {
          success: true,
          data: JSON.parse(response.body, symbolize_names: true)
        }
      else
        {
          success: false,
          error: "HeyHo API error: #{response.code} - #{response.message}"
        }
      end
    rescue StandardError => e
      Rails.logger.error("HeyHo API error: #{e.message}")
      {
        success: false,
        error: "Failed to fetch browsing insights: #{e.message}"
      }
    end

    # Fetch browsing insights summary
    def fetch_browsing_summary(heyho_user_id:, days: 7)
      uri = URI("#{heyho_base_url}/api/v1/browsing_data/summary")
      uri.query = URI.encode_www_form(user_id: heyho_user_id, days: days)

      request = Net::HTTP::Get.new(uri)
      request['Content-Type'] = 'application/json'
      request['X-Service-Secret'] = service_secret

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        {
          success: true,
          data: JSON.parse(response.body, symbolize_names: true)
        }
      else
        {
          success: false,
          error: "HeyHo API error: #{response.code} - #{response.message}"
        }
      end
    rescue StandardError => e
      Rails.logger.error("HeyHo API error: #{e.message}")
      {
        success: false,
        error: "Failed to fetch browsing summary: #{e.message}"
      }
    end

    # Fetch hoarder tabs (smart recommendations) for a HeyHo user
    def fetch_browsing_sessions(heyho_user_id:, limit: nil)
      # Call the hoarder_tabs endpoint which returns smart tab recommendations
      # No limit means get all hoarder tabs
      params = { lookback_days: 30 }
      params[:limit] = limit if limit.present?

      uri = URI("#{heyho_base_url}/api/v1/pattern_detections/hoarder_tabs")
      uri.query = URI.encode_www_form(params)

      request = Net::HTTP::Get.new(uri)
      request['Content-Type'] = 'application/json'
      # Service-to-service authentication
      request['X-Service-Secret'] = service_secret
      request['X-HeyHo-User-Id'] = heyho_user_id.to_s

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        parsed = JSON.parse(response.body, symbolize_names: true)
        # Transform hoarder tabs into a format compatible with our frontend
        hoarder_tabs = parsed.dig(:data, :hoarder_tabs) || []

        {
          success: true,
          data: {
            research_sessions: hoarder_tabs.map { |tab| transform_hoarder_tab(tab) },
            count: hoarder_tabs.size
          }
        }
      else
        {
          success: false,
          error: "HeyHo API error: #{response.code} - #{response.message}"
        }
      end
    rescue StandardError => e
      Rails.logger.error("HeyHo API error: #{e.message}")
      {
        success: false,
        error: "Failed to fetch browsing sessions: #{e.message}"
      }
    end

    # Transform hoarder tab format to match expected frontend format
    def transform_hoarder_tab(tab)
      {
        id: tab[:page_visit_id] || tab[:id],
        title: tab[:title],
        status: 'recommended',
        research_session_tabs: [
          {
            id: tab[:page_visit_id] || tab[:id],
            url: tab[:url],
            title: tab[:title],
            domain: tab[:domain],
            tab_order: 1,
            preview: tab[:preview]
          }
        ]
      }
    end

    private

    def heyho_base_url
      ENV.fetch('HEYHO_SYNC_API_URL', 'http://localhost:3001')
    end

    def service_secret
      ENV.fetch('SERVICE_SECRET', Rails.application.secret_key_base)
    end

    def parse_token_response(response)
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body, symbolize_names: true)
        {
          success: true,
          user_id: data[:user_id],
          email: data[:email],
          first_name: data[:first_name],
          last_name: data[:last_name],
          scope: data[:scope]
        }
      else
        error_data = begin
          JSON.parse(response.body, symbolize_names: true)
        rescue StandardError
          {}
        end
        {
          success: false,
          error: error_data[:error_description] || error_data[:error] || 'Unknown error'
        }
      end
    end
  end
end
