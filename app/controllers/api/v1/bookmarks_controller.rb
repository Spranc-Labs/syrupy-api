# frozen_string_literal: true

module Api
  module V1
    class BookmarksController < ApiController
      before_action :set_bookmark, only: [:show, :update, :destroy, :mark_as_read, :archive, :favorite]
      before_action :authorize_bookmark, only: [:show, :update, :destroy, :mark_as_read, :archive, :favorite]

      # GET /api/v1/bookmarks
      def index
        @bookmarks = policy_scope(Bookmark)
                     .kept
                     .includes(:collection, :tags)

        # Apply filters
        @bookmarks = @bookmarks.by_collection(params[:collection_id]) if params[:collection_id].present?
        @bookmarks = @bookmarks.by_tag(params[:tag_id]) if params[:tag_id].present?
        @bookmarks = @bookmarks.by_status(params[:status]) if params[:status].present?
        @bookmarks = @bookmarks.from_heyho if params[:from_heyho] == 'true'

        # Apply search
        @bookmarks = apply_search(@bookmarks, params[:search]) if params[:search].present?

        # Apply sorting
        @bookmarks = apply_sorting(@bookmarks, params[:sort_by] || 'saved_at')

        # Paginate
        @bookmarks = @bookmarks.page(params[:page]).per(params[:per_page] || 20)

        render json: BookmarkBlueprint.render(@bookmarks, view: :with_tags)
      end

      # GET /api/v1/bookmarks/:id
      def show
        render json: BookmarkBlueprint.render(@bookmark, view: :detailed)
      end

      # POST /api/v1/bookmarks
      def create
        @bookmark = current_user.bookmarks.build(bookmark_params)
        authorize @bookmark

        # Handle tags
        attach_tags_by_name(params[:bookmark][:tag_names]) if params[:bookmark][:tag_names].present?

        if @bookmark.save
          render json: BookmarkBlueprint.render(@bookmark, view: :with_tags), status: :created
        else
          render json: { errors: @bookmark.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/bookmarks/from_heyho
      def from_heyho
        bookmark_params = build_bookmark_from_heyho_params

        @bookmark = current_user.bookmarks.build(bookmark_params)
        authorize @bookmark

        # Find or create collection
        if params[:collection_id].present?
          @bookmark.collection_id = params[:collection_id]
        elsif params[:collection_name].present?
          collection = current_user.collections.find_or_create_by!(name: params[:collection_name])
          @bookmark.collection_id = collection.id
        end

        # Attach tags
        if params[:tags].present?
          tag_names = params[:tags].is_a?(Array) ? params[:tags] : params[:tags].split(',').map(&:strip)
          attach_tags_by_name(tag_names)
        end

        if @bookmark.save
          render json: BookmarkBlueprint.render(@bookmark, view: :with_tags), status: :created
        else
          render json: { errors: @bookmark.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/bookmarks/:id
      def update
        # Handle tags separately
        update_tags_by_name(params[:bookmark][:tag_names]) if params[:bookmark][:tag_names].present?

        if @bookmark.update(bookmark_params)
          render json: BookmarkBlueprint.render(@bookmark, view: :with_tags)
        else
          render json: { errors: @bookmark.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/bookmarks/:id
      def destroy
        if @bookmark.discard
          head :no_content
        else
          render json: { errors: @bookmark.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/bookmarks/:id/mark_as_read
      def mark_as_read
        if @bookmark.mark_as_read!
          render json: BookmarkBlueprint.render(@bookmark)
        else
          render json: { errors: @bookmark.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/bookmarks/:id/archive
      def archive
        if @bookmark.archive!
          render json: BookmarkBlueprint.render(@bookmark)
        else
          render json: { errors: @bookmark.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/bookmarks/:id/favorite
      def favorite
        success = if params[:unfavorite] == 'true'
                    @bookmark.unfavorite!
                  else
                    @bookmark.favorite!
                  end

        if success
          render json: BookmarkBlueprint.render(@bookmark)
        else
          render json: { errors: @bookmark.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/bookmarks/bulk_update
      def bulk_update
        bookmark_ids = params[:bookmark_ids] || []
        action = params[:action]

        Bookmark.transaction do
          bookmarks = current_user.bookmarks.where(id: bookmark_ids)

          case action
          when 'move_to_collection'
            bookmarks.update_all(collection_id: params[:collection_id])
          when 'add_tags'
            tag_names = params[:tag_names] || []
            tags = find_or_create_tags(tag_names)
            bookmarks.each { |bookmark| bookmark.tags << tags }
          when 'mark_as_read'
            bookmarks.update_all(status: 'read', read_at: Time.current)
          when 'archive'
            bookmarks.update_all(status: 'archived', archived_at: Time.current)
          else
            raise ArgumentError, "Invalid action: #{action}"
          end
        end

        head :no_content
      rescue ArgumentError => e
        render json: { errors: [e.message] }, status: :unprocessable_entity
      end

      private

      def set_bookmark
        @bookmark = Bookmark.kept.find(params[:id])
      end

      def authorize_bookmark
        authorize @bookmark
      end

      def bookmark_params
        params.require(:bookmark).permit(
          :url, :title, :description, :note, :collection_id, :status,
          :heyho_page_visit_id, :source, metadata: {}
        )
      end

      def build_bookmark_from_heyho_params
        {
          url: params[:url],
          title: params[:title],
          description: params[:description],
          metadata: params[:metadata] || {},
          source: 'heyho',
          heyho_page_visit_id: params[:page_visit_id]
        }
      end

      def attach_tags_by_name(tag_names)
        tag_names = tag_names.split(',').map(&:strip) unless tag_names.is_a?(Array)
        tags = find_or_create_tags(tag_names)
        @bookmark.tags = tags
      end

      def update_tags_by_name(tag_names)
        tag_names = tag_names.split(',').map(&:strip) unless tag_names.is_a?(Array)
        tags = find_or_create_tags(tag_names)
        @bookmark.tags = tags
      end

      def find_or_create_tags(tag_names)
        tag_names.map do |name|
          Tag.find_or_create_by!(name: name.strip, kind: 'user')
        end
      end

      def apply_search(scope, query)
        scope.where(
          "url ILIKE ? OR title ILIKE ? OR description ILIKE ? OR metadata->>'domain' ILIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
        )
      end

      def apply_sorting(scope, sort_by)
        case sort_by
        when 'saved_at'
          scope.order(saved_at: :desc)
        when 'read_at'
          scope.order(read_at: :desc)
        when 'title'
          scope.order(title: :asc)
        when 'url'
          scope.order(url: :asc)
        else
          scope.order(saved_at: :desc)
        end
      end
    end
  end
end
