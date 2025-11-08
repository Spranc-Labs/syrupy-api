# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Collection do
  describe 'associations' do
    it 'belongs to user' do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'has many bookmarks' do
      expect(described_class.reflect_on_association(:bookmarks).macro).to eq(:has_many)
    end
  end

  describe 'validations' do
    it 'validates presence of name' do
      collection = build(:collection, name: nil)
      expect(collection).not_to be_valid
      expect(collection.errors[:name]).to include("can't be blank")
    end

    it 'validates uniqueness of name scoped to user' do
      user = create(:user)
      create(:collection, name: 'Test', user: user)
      duplicate = build(:collection, name: 'Test', user: user)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end

    context 'color validation' do
      it 'accepts valid hex colors' do
        collection = build(:collection, color: '#ff5733')
        expect(collection).to be_valid
      end

      it 'rejects invalid color formats' do
        collection = build(:collection, color: 'red')
        expect(collection).not_to be_valid
        expect(collection.errors[:color]).to be_present
      end

      it 'allows blank colors' do
        collection = build(:collection, color: nil)
        expect(collection).to be_valid
      end
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:auto_created_default) { user.collections.defaults.first }
    let!(:active_collection) { create(:collection, user: user) }
    let!(:discarded_collection) { create(:collection, user: user, discarded_at: Time.current) }

    describe '.active' do
      it 'returns only kept collections' do
        collections = described_class.where(user: user).active
        expect(collections).to include(active_collection)
        expect(collections).to include(auto_created_default)
        expect(collections).not_to include(discarded_collection)
      end
    end

    describe '.by_position' do
      let!(:collection1) { create(:collection, user: user, position: 2) }
      let!(:collection2) { create(:collection, user: user, position: 1) }
      let!(:collection3) { create(:collection, user: user, position: 3) }

      it 'orders collections by position ascending' do
        ordered = described_class.where(user: user).by_position.to_a
        expect(ordered.index(collection2)).to be < ordered.index(collection1)
        expect(ordered.index(collection1)).to be < ordered.index(collection3)
      end
    end

    describe '.defaults' do
      it 'returns only default collections' do
        defaults = described_class.where(user: user).defaults
        expect(defaults.count).to eq(1)
        expect(defaults.first).to eq(auto_created_default)
      end
    end
  end

  describe 'callbacks' do
    describe '#set_default_color' do
      it 'sets default color when color is blank' do
        collection = create(:collection, color: nil)
        expect(collection.color).to eq('#6366f1')
      end

      it 'does not override provided color' do
        collection = create(:collection, color: '#ff5733')
        expect(collection.color).to eq('#ff5733')
      end
    end

    describe '#ensure_single_default' do
      let(:user) { create(:user) }
      let!(:first_default) { create(:collection, :default, user: user) }

      it 'unsets other default collections when creating a new default' do
        expect(first_default.reload.is_default).to be true

        second_default = create(:collection, :default, user: user)

        expect(first_default.reload.is_default).to be false
        expect(second_default.reload.is_default).to be true
      end

      it 'does not affect non-default collections' do
        non_default = create(:collection, user: user, is_default: false)
        expect(first_default.reload.is_default).to be true
        expect(non_default.reload.is_default).to be false
      end
    end
  end

  describe '#bookmarks_count' do
    let(:collection) { create(:collection, :with_bookmarks) }

    it 'returns the count of kept bookmarks' do
      expect(collection.bookmarks_count).to eq(3)
    end

    it 'excludes discarded bookmarks' do
      collection.bookmarks.first.discard
      expect(collection.bookmarks_count).to eq(2)
    end
  end

  describe 'soft delete with discard' do
    let(:collection) { create(:collection) }

    it 'can be soft deleted' do
      collection.discard
      expect(collection).to be_discarded
    end

    it 'can be restored' do
      collection.discard
      collection.undiscard
      expect(collection).not_to be_discarded
    end
  end
end
