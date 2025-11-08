# frozen_string_literal: true

module Api
  module V1
    # BrowsingSessionsController handles fetching browsing sessions from HeyHo
    class BrowsingSessionsController < ApiController
      skip_after_action :verify_authorized
      skip_after_action :verify_policy_scoped

      # GET /api/v1/browsing_sessions
      # Fetch user's browsing sessions from HeyHo (requires linked account)
      def index
        unless current_user.heyho_user_id.present?
          return render json: {
            error: 'HeyHo account not linked. Please link your account first.'
          }, status: :unauthorized
        end

        # Fetch sessions from HeyHo Sync-BE
        # Pass nil for limit to get all hoarder tabs
        result = HeyhoApiService.fetch_browsing_sessions(
          heyho_user_id: current_user.heyho_user_id,
          limit: params[:limit] # No default - nil means all tabs
        )

        if result[:success]
          render json: {
            sessions: result[:data][:research_sessions] || [],
            count: result[:data][:count] || 0
          }
        else
          render json: {
            error: result[:error] || 'Failed to fetch browsing sessions'
          }, status: :service_unavailable
        end
      rescue StandardError => e
        Rails.logger.error("Failed to fetch browsing sessions: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        render json: {
          error: Rails.env.development? ? e.message : 'Failed to fetch browsing sessions'
        }, status: :internal_server_error
      end
    end
  end
end
