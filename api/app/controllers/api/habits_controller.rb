class Api::HabitsController < ApiController
  def index
    habits = policy_scope(Habit).includes(:user)
                               .order(:name)
                               .paginate(page: params[:page], per_page: params[:per_page])
    
    render_page_with_blueprint(
      collection: habits,
      blueprint: HabitBlueprint
    )
  end

  def show
    habit = Habit.find(params[:id])
    authorize(habit)
    render json: HabitBlueprint.render(habit)
  end

  def create
    habit = Habit.new(habit_params)
    authorize(habit)
    
    if habit.save
      render json: HabitBlueprint.render(habit), status: :created
    else
      render json: { errors: habit.errors }, status: :unprocessable_entity
    end
  end

  def update
    habit = Habit.find(params[:id])
    authorize(habit)
    
    if habit.update(habit_params)
      render json: HabitBlueprint.render(habit)
    else
      render json: { errors: habit.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    habit = Habit.find(params[:id])
    authorize(habit)
    habit.discard
    head :no_content
  end

  def log_completion
    habit = Habit.find(params[:id])
    authorize(habit)
    
    habit_log = HabitLog.new(
      habit: habit,
      user: Current.user,
      logged_date: Date.current,
      completed: true
    )
    
    if habit_log.save
      render json: HabitLogBlueprint.render(habit_log), status: :created
    else
      render json: { errors: habit_log.errors }, status: :unprocessable_entity
    end
  end

  def streaks
    habits = policy_scope(Habit).includes(:habit_logs)
    authorize(habits)
    
    streaks = habits.map do |habit|
      {
        id: habit.id,
        name: habit.name,
        current_streak: habit.current_streak,
        longest_streak: habit.longest_streak
      }
    end
    
    render json: { streaks: streaks }
  end

  private

  def habit_params
    params.require(:habit).permit(:name, :description, :frequency, :active)
          .merge(user: Current.user)
  end
end 