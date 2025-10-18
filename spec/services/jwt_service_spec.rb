# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JwtService do
  describe '.encode' do
    it 'creates a valid JWT token with account_id' do
      token = described_class.encode(account_id: 1)
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3) # JWT has 3 parts
    end

    it 'includes account_id in payload' do
      token = described_class.encode(account_id: 42)
      payload = described_class.decode(token)
      expect(payload[:account_id]).to eq(42)
    end
  end

  describe '.encode_refresh_token' do
    it 'creates a refresh token with type marker' do
      token = described_class.encode_refresh_token(account_id: 1)
      payload = described_class.decode(token)
      expect(payload[:type]).to eq('refresh')
    end
  end

  describe '.decode' do
    it 'decodes a valid token' do
      token = described_class.encode(account_id: 99)
      payload = described_class.decode(token)
      expect(payload[:account_id]).to eq(99)
    end

    it 'returns nil for invalid token' do
      payload = described_class.decode('invalid.token.here')
      expect(payload).to be_nil
    end
  end

  describe '.refresh_access_token' do
    it 'generates new access token from refresh token' do
      refresh_token = described_class.encode_refresh_token(account_id: 5)
      new_token = described_class.refresh_access_token(refresh_token)
      expect(new_token).to be_a(String)

      payload = described_class.decode(new_token)
      expect(payload[:account_id]).to eq(5)
      expect(payload[:type]).to be_nil # Access tokens don't have type
    end

    it 'returns nil for non-refresh tokens' do
      access_token = described_class.encode(account_id: 1)
      new_token = described_class.refresh_access_token(access_token)
      expect(new_token).to be_nil
    end
  end
end
