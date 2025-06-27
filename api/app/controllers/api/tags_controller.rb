class Api::TagsController < ApiController
  def index
    tags = policy_scope(Tag).all
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
    params.require(:tag).permit(:name, :color)
  end
end 