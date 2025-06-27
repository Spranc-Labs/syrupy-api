module Api
  class GoalsController < ApiController
    def index
      goals = policy_scope(Goal)
        .includes(:user)
        .filter_by_text(params[:q])

      goals = goals.by_status(params[:status]) if params[:status].present?
      goals = goals.by_priority(params[:priority]) if params[:priority].present?

      goals = goals
        .order(:target_date, :created_at)
        .paginate(page: params[:page], per_page: params[:per_page])

      associations = { user: {} }
      render_page_with_blueprint(collection: goals, blueprint: GoalBlueprint, associations:)
    end

    def show
      goal = policy_scope(Goal).find(params[:id])
      associations = { user: {} }

      render json: { data: GoalBlueprint.render_with_associations(goal, associations) }
    end

    def create
      authorize(Goal)

      goal = Goal.new(goal_params)
      goal.user = Current.user
      goal.save!

      render json: { data: GoalBlueprint.render_as_hash(goal) }, status: :created
    end

    def update
      goal = Goal.find(params[:id])
      authorize(goal)

      goal.update!(goal_params)
      render json: { data: GoalBlueprint.render_as_hash(goal) }
    end

    def destroy
      goal = Goal.find(params[:id])
      authorize(goal)
      goal.discard!
      head :no_content
    end

    private

    def goal_params
      params.permit(:title, :description, :status, :priority, :target_date)
    end
  end
end 