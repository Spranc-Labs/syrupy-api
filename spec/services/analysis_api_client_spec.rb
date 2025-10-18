# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JournalAnalysisApiClient do
  describe '.analyze' do
    let(:title) { 'Test Entry' }
    let(:content) { 'This is a test journal entry.' }

    context 'when API is available' do
      before do
        stub_request(:post, "#{described_class::BASE_URL}/analyze")
          .to_return(
            status: 200,
            body: {
              mood: { label: 'positive', score: 0.7 },
              category: { label: 'personal_growth', confidence: 0.8 }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns analysis data' do
        result = described_class.analyze(title: title, content: content)
        expect(result).to be_a(Hash)
        expect(result['mood']).to be_present
        expect(result['category']).to be_present
      end
    end

    context 'when API times out' do
      before do
        stub_request(:post, "#{described_class::BASE_URL}/analyze")
          .to_timeout
      end

      it 'raises TimeoutError' do
        expect do
          described_class.analyze(title: title, content: content)
        end.to raise_error(JournalAnalysisApiClient::TimeoutError)
      end
    end

    context 'when API returns error' do
      before do
        stub_request(:post, "#{described_class::BASE_URL}/analyze")
          .to_return(status: 500)
      end

      it 'raises ConnectionError' do
        expect do
          described_class.analyze(title: title, content: content)
        end.to raise_error(JournalAnalysisApiClient::ConnectionError)
      end
    end
  end
end
