# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Credentials do
  describe '.get' do
    context 'when ENV variable exists' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('TEST_KEY', nil).and_return('env_value')
      end

      it 'returns ENV value' do
        result = described_class.get(:test, :key)
        expect(result).to eq('env_value')
      end
    end

    context 'when ENV variable does not exist' do
      before do
        allow(ENV).to receive(:fetch).with('TEST_KEY', nil).and_return(nil)
        allow(Rails.application.credentials).to receive(:dig).with(:test, :key).and_return('credentials_value')
      end

      it 'falls back to Rails credentials' do
        result = described_class.get(:test, :key)
        expect(result).to eq('credentials_value')
      end
    end
  end
end
