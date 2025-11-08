# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Collections' do
  let(:user) { create(:user) }
  let(:auth_headers) { auth_headers_for(user) }

  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call).and_call_original
  end

  describe 'GET /api/v1/collections' do
    context 'when authenticated' do
      let!(:collections) { create_list(:collection, 3, user: user) }
      let!(:other_user_collection) { create(:collection) }

      before { get '/api/v1/collections', headers: auth_headers }

      it 'returns success status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns only the current user collections' do
        response_json = JSON.parse(response.body, symbolize_names: true)
        collection_ids = response_json.map { |c| c[:id] }

        expect(collection_ids).to match_array(collections.map(&:id))
        expect(collection_ids).not_to include(other_user_collection.id)
      end

      it 'includes bookmarks count' do
        response_json = JSON.parse(response.body, symbolize_names: true)
        expect(response_json.first).to have_key(:bookmarks_count)
      end
    end

    context 'when not authenticated' do
      before { get '/api/v1/collections' }

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/collections/:id' do
    let(:collection) { create(:collection, :with_bookmarks, user: user) }

    context 'when authenticated and owns the collection' do
      before { get "/api/v1/collections/#{collection.id}", headers: auth_headers }

      it 'returns success status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the collection details' do
        response_json = JSON.parse(response.body, symbolize_names: true)

        expect(response_json[:id]).to eq(collection.id)
        expect(response_json[:name]).to eq(collection.name)
        expect(response_json[:color]).to eq(collection.color)
      end
    end

    context 'when trying to access another user collection' do
      let(:other_collection) { create(:collection) }

      it 'raises authorization error' do
        expect do
          get "/api/v1/collections/#{other_collection.id}", headers: auth_headers
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when not authenticated' do
      before { get "/api/v1/collections/#{collection.id}" }

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/collections' do
    let(:valid_params) do
      {
        collection: {
          name: 'My New Collection',
          color: '#ff5733',
          description: 'A test collection',
          position: 1
        }
      }
    end

    let(:invalid_params) do
      {
        collection: {
          name: '',
          color: 'invalid-color'
        }
      }
    end

    context 'when authenticated with valid params' do
      it 'creates a new collection' do
        expect do
          post '/api/v1/collections', params: valid_params, headers: auth_headers
        end.to change(Collection, :count).by(1)
      end

      it 'returns created status' do
        post '/api/v1/collections', params: valid_params, headers: auth_headers
        expect(response).to have_http_status(:created)
      end

      it 'returns the created collection' do
        post '/api/v1/collections', params: valid_params, headers: auth_headers
        response_json = JSON.parse(response.body, symbolize_names: true)

        expect(response_json[:name]).to eq('My New Collection')
        expect(response_json[:color]).to eq('#ff5733')
        expect(response_json[:description]).to eq('A test collection')
      end

      it 'associates the collection with the current user' do
        post '/api/v1/collections', params: valid_params, headers: auth_headers
        expect(Collection.last.user).to eq(user)
      end
    end

    context 'when authenticated with invalid params' do
      before { post '/api/v1/collections', params: invalid_params, headers: auth_headers }

      it 'returns unprocessable entity status' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        response_json = JSON.parse(response.body, symbolize_names: true)
        expect(response_json[:errors]).to be_present
      end

      it 'does not create a collection' do
        expect do
          post '/api/v1/collections', params: invalid_params, headers: auth_headers
        end.not_to change(Collection, :count)
      end
    end

    context 'when not authenticated' do
      before { post '/api/v1/collections', params: valid_params }

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/collections/:id' do
    let(:collection) { create(:collection, user: user, name: 'Original Name') }
    let(:update_params) do
      {
        collection: {
          name: 'Updated Name',
          color: '#00ff00'
        }
      }
    end

    context 'when authenticated and owns the collection' do
      before { patch "/api/v1/collections/#{collection.id}", params: update_params, headers: auth_headers }

      it 'returns success status' do
        expect(response).to have_http_status(:ok)
      end

      it 'updates the collection' do
        collection.reload
        expect(collection.name).to eq('Updated Name')
        expect(collection.color).to eq('#00ff00')
      end

      it 'returns the updated collection' do
        response_json = JSON.parse(response.body, symbolize_names: true)
        expect(response_json[:name]).to eq('Updated Name')
      end
    end

    context 'when trying to update another user collection' do
      let(:other_collection) { create(:collection) }

      it 'raises authorization error' do
        expect do
          patch "/api/v1/collections/#{other_collection.id}", params: update_params, headers: auth_headers
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when not authenticated' do
      before { patch "/api/v1/collections/#{collection.id}", params: update_params }

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/collections/:id' do
    let!(:default_collection) { create(:collection, :default, user: user) }
    let!(:collection) { create(:collection, :with_bookmarks, user: user) }

    context 'when authenticated and owns the collection' do
      before { delete "/api/v1/collections/#{collection.id}", headers: auth_headers }

      it 'returns no content status' do
        expect(response).to have_http_status(:no_content)
      end

      it 'soft deletes the collection' do
        expect(Collection.kept.find_by(id: collection.id)).to be_nil
        expect(Collection.discarded.find_by(id: collection.id)).to be_present
      end

      it 'moves bookmarks to default collection' do
        expect(default_collection.bookmarks.count).to eq(3)
      end
    end

    context 'when trying to delete another user collection' do
      let(:other_collection) { create(:collection) }

      it 'raises authorization error' do
        expect do
          delete "/api/v1/collections/#{other_collection.id}", headers: auth_headers
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when not authenticated' do
      before { delete "/api/v1/collections/#{collection.id}" }

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
