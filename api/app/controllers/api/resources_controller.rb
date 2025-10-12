module Api
  class ResourcesController < ApiController
    before_action :set_resource, only: [:show, :update, :destroy]
    before_action :authorize_resource, only: [:show, :update, :destroy]

    def index
      @resources = policy_scope(Resource)
        .includes(:tags, :resource_content)
        .recent

      # Filter by status if provided
      @resources = @resources.by_status(params[:status]) if params[:status].present?
      
      # Search by URL or title
      if params[:search].present?
        @resources = @resources.where(
          "url ILIKE ? OR title ILIKE ?", 
          "%#{params[:search]}%", "%#{params[:search]}%"
        )
      end

      @resources = @resources
        .paginate(page: params[:page], per_page: params[:per_page] || 20)

      render json: ResourceBlueprint.render(@resources)
    end

    def show
      view = params[:include_content] == 'true' ? :with_content : :default
      render json: ResourceBlueprint.render(@resource, view: view)
    end

    def create
      @resource = current_user.resources.build(resource_params)
      authorize @resource

      if @resource.save
        render json: ResourceBlueprint.render(@resource), status: :created
      else
        render json: { errors: @resource.errors }, status: :unprocessable_entity
      end
    end

    def update
      if @resource.update(resource_params)
        render json: ResourceBlueprint.render(@resource)
      else
        render json: { errors: @resource.errors }, status: :unprocessable_entity
      end
    end

    def destroy
      @resource.destroy
      head :no_content
    end

    private

    def set_resource
      @resource = Resource.find(params[:id])
    end

    def authorize_resource
      authorize @resource
    end

    def resource_params
      params.permit(:url, :title, :status, :metadata, tag_ids: [])
    end
  end
end 