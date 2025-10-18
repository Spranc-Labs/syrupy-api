# frozen_string_literal: true

module Api
  class BrowsingInsightsController < ApplicationController
    # GET /api/browsing_insights
    # For now, hardcode demo user for testing
    def index
      result = BrowsingDataService.fetch_browsing_data(
        user_email: 'demo@syrupy.com',  # Hardcoded for testing
        page: params[:page] || 1,
        per_page: params[:per_page] || 50
      )

      if result.success?
        render json: result.data, status: :ok
      else
        render json: { success: false, errors: result.errors }, status: :unprocessable_entity
      end
    end

    # GET /api/browsing_insights/summary
    def summary
      result = BrowsingDataService.fetch_summary(user_email: 'demo@syrupy.com')  # Hardcoded for testing

      if result.success?
        render json: result.data, status: :ok
      else
        render json: { success: false, errors: result.errors }, status: :unprocessable_entity
      end
    end
  end
end
