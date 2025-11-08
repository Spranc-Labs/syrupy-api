# frozen_string_literal: true

module Api
  module V1
    class CollectionsController < ApiController
      before_action :set_collection, only: [:show, :update, :destroy]
      before_action :authorize_collection, only: [:show, :update, :destroy]

      # GET /api/v1/collections
      def index
        @collections = policy_scope(Collection)
                       .kept
                       .by_position
                       .paginate(page: params[:page], per_page: params[:per_page] || 20)

        render json: CollectionBlueprint.render(@collections, view: :with_counts)
      end

      # GET /api/v1/collections/:id
      def show
        render json: CollectionBlueprint.render(@collection, view: :with_bookmarks)
      end

      # POST /api/v1/collections
      def create
        @collection = current_user.collections.build(collection_params)
        authorize @collection

        if @collection.save
          render json: CollectionBlueprint.render(@collection), status: :created
        else
          render json: { errors: @collection.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/collections/:id
      def update
        if @collection.update(collection_params)
          render json: CollectionBlueprint.render(@collection)
        else
          render json: { errors: @collection.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/collections/:id
      def destroy
        # Move bookmarks to default collection before deleting
        default_collection = current_user.collections.defaults.first

        if default_collection && @collection.id != default_collection.id
          @collection.bookmarks.update_all(collection_id: default_collection.id)
        end

        if @collection.discard
          head :no_content
        else
          render json: { errors: @collection.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/collections/reorder
      def reorder
        Collection.transaction do
          params[:collections].each do |collection_data|
            collection = current_user.collections.find(collection_data[:id])
            collection.update!(position: collection_data[:position])
          end
        end

        head :no_content
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: [e.message] }, status: :unprocessable_entity
      end

      private

      def set_collection
        @collection = Collection.kept.find(params[:id])
      end

      def authorize_collection
        authorize @collection
      end

      def collection_params
        params.require(:collection).permit(:name, :icon, :color, :description, :position, :is_default)
      end
    end
  end
end
