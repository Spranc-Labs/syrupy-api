# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::BrowsingInsights' do
  before do
    # Allow any host for request specs
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call).and_call_original
  end

  describe 'GET /api/v1/browsing_insights' do
    it 'returns placeholder message' do
      get '/api/v1/browsing_insights', headers: { 'Host' => 'api' }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['message']).to include('coming soon')
    end
  end

  describe 'GET /api/v1/browsing_insights/summary' do
    it 'returns placeholder message' do
      get '/api/v1/browsing_insights/summary', headers: { 'Host' => 'api' }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['message']).to include('coming soon')
    end
  end
end
