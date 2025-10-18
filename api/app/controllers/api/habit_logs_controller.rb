# frozen_string_literal: true

class Api::HabitLogsController < ApiController
  def index
    habit_logs = policy_scope(HabitLog).includes(:user, :habit)
                                      .order(logged_date: :desc)
                                      .paginate(page: params[:page], per_page: params[:per_page])
    
    render_page_with_blueprint(
      collection: habit_logs,
      blueprint: HabitLogBlueprint
    )
  end

  def show
    habit_log = HabitLog.find(params[:id])
    authorize(habit_log)
    render json: HabitLogBlueprint.render(habit_log)
  end

  def create
    habit_log = HabitLog.new(habit_log_params)
    authorize(habit_log)
    
    if habit_log.save
      render json: HabitLogBlueprint.render(habit_log), status: :created
    else
      render json: { errors: habit_log.errors }, status: :unprocessable_entity
    end
  end

  def update
    habit_log = HabitLog.find(params[:id])
    authorize(habit_log)
    
    if habit_log.update(habit_log_params)
      render json: HabitLogBlueprint.render(habit_log)
    else
      render json: { errors: habit_log.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    habit_log = HabitLog.find(params[:id])
    authorize(habit_log)
    habit_log.discard
    head :no_content
  end

  private

  def habit_log_params
    params.require(:habit_log).permit(:habit_id, :logged_date, :completed, :notes)
          .merge(user: Current.user)
  end
end 