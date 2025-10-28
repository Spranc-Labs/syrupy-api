# frozen_string_literal: true

module Api
  module V1
    # AccountLinksController handles linking/unlinking HeyHo browser extension accounts
    class AccountLinksController < ApiController
      skip_after_action :verify_authorized
      skip_after_action :verify_policy_scoped

      # GET /api/v1/account_links/status
      # Check if user has linked their HeyHo account
      def status
        render json: {
          linked: current_user.heyho_user_id.present?,
          heyho_user_id: current_user.heyho_user_id,
          linked_at: current_user.heyho_linked_at
        }
      end

      # POST /api/v1/account_links
      # Initiate OAuth flow - returns HeyHo authorization URL
      def create
        heyho_base_url = ENV.fetch('HEYHO_SYNC_API_URL', 'http://localhost:3001')
        client_id = 'syrupy'
        redirect_uri = params[:redirect_uri] || "#{request.base_url}/auth/heyho/callback"

        authorize_url = "#{heyho_base_url}/api/v1/oauth/authorize?" \
                       "client_id=#{CGI.escape(client_id)}&" \
                       "redirect_uri=#{CGI.escape(redirect_uri)}&" \
                       "scope=browsing_data:read"

        render json: {
          authorize_url: authorize_url,
          client_id: client_id,
          redirect_uri: redirect_uri
        }, status: :created
      end

      # POST /api/v1/account_links/callback
      # Handle OAuth callback - exchange code for user info
      def callback
        unless params[:code].present?
          return render json: {
            error: 'Missing authorization code'
          }, status: :bad_request
        end

        # Exchange authorization code for HeyHo user info
        result = HeyhoApiService.exchange_authorization_code(
          code: params[:code],
          redirect_uri: params[:redirect_uri]
        )

        if result[:success]
          # Link the HeyHo account
          current_user.update!(
            heyho_user_id: result[:user_id],
            heyho_linked_at: Time.current
          )

          render json: {
            success: true,
            message: 'Successfully linked HeyHo account',
            heyho_user_id: result[:user_id],
            linked_at: current_user.heyho_linked_at
          }
        else
          render json: {
            success: false,
            error: result[:error] || 'Failed to link HeyHo account'
          }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error("Failed to link HeyHo account: #{e.message}")
        render json: {
          success: false,
          error: 'Failed to link HeyHo account. Please try again.'
        }, status: :internal_server_error
      end

      # DELETE /api/v1/account_links
      # Unlink HeyHo account
      def destroy
        unless current_user.heyho_user_id.present?
          return render json: {
            error: 'No HeyHo account linked'
          }, status: :not_found
        end

        current_user.update!(
          heyho_user_id: nil,
          heyho_linked_at: nil
        )

        render json: {
          success: true,
          message: 'Successfully unlinked HeyHo account'
        }
      end
    end
  end
end
