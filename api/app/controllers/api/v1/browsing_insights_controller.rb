# frozen_string_literal: true

module Api
  module V1
    class BrowsingInsightsController < ApplicationController
      # GET /api/v1/browsing_insights
      # Placeholder - browsing insights feature not yet implemented
      def index
        render json: {
          message: 'Browsing insights feature coming soon',
          data: []
        }, status: :ok
      end

      # GET /api/v1/browsing_insights/summary
      # Placeholder - browsing insights feature not yet implemented
      def summary
        render json: {
          message: 'Browsing insights summary coming soon',
          data: {}
        }, status: :ok
      end
    end
  end
end
