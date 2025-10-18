# frozen_string_literal: true

module Api
  module V1
    class TagsController < Api::V1::ApiController
      def index
        tags = policy_scope(Tag).all

        # Filter by kind if specified
        tags = tags.where(kind: params[:kind]) if params[:kind].present?

        # Filter by text search if specified
        tags = tags.filter_by_text(params[:search]) if params[:search].present?

        # Order by popularity for user tags, by name for system tags
        tags = if params[:kind] == 'user'
                 tags.popular
               else
                 tags.order(:name)
               end

        render json: TagBlueprint.render(tags)
      end

      def show
        tag = Tag.find(params[:id])
        authorize(tag)
        render json: TagBlueprint.render(tag)
      end

      def create
        tag = Tag.new(tag_params)
        authorize(tag)

        if tag.save
          render json: TagBlueprint.render(tag), status: :created
        else
          render json: { errors: tag.errors }, status: :unprocessable_entity
        end
      end

      def update
        tag = Tag.find(params[:id])
        authorize(tag)

        if tag.update(tag_params)
          render json: TagBlueprint.render(tag)
        else
          render json: { errors: tag.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        tag = Tag.find(params[:id])
        authorize(tag)
        tag.discard
        head :no_content
      end

      private

      def tag_params
        permitted = params.require(:tag).permit(:name, :color, :kind)
        # Default to 'user' kind if not specified
        permitted[:kind] ||= 'user'
        permitted
      end
    end
  end
end
