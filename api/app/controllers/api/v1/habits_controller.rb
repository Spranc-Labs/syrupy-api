# frozen_string_literal: true

module Api
  module V1
    class HabitsController < ApiController
      before_action :set_habit, only: [:show, :update, :destroy, :log_completion, :toggle_active]
      before_action :authorize_habit, only: [:show, :update, :destroy, :log_completion, :toggle_active]
      skip_after_action :verify_policy_scoped, only: [:streaks, :stats, :dashboard, :bulk_log, :history]

      def index
        @habits = policy_scope(Habit)
          .includes(:user, :habit_logs)

        # Filter by active status
        @habits = @habits.where(active: params[:active]) if params[:active].present?

        # Search by name or description
        if params[:q].present?
          @habits = @habits.where(
            "name ILIKE ? OR description ILIKE ?",
            "%#{params[:q]}%", "%#{params[:q]}%"
          )
        end

        # Filter by frequency
        @habits = @habits.where(frequency: params[:frequency]) if params[:frequency].present?

        @habits = @habits
          .order(:name)
          .paginate(page: params[:page], per_page: params[:per_page] || 20)

        render json: HabitBlueprint.render(@habits)
      end

      def show
        render json: HabitBlueprint.render(@habit, include: [:habit_logs])
      end

      def create
        @habit = current_user.habits.build(habit_params)
        authorize @habit

        if @habit.save
          render json: HabitBlueprint.render(@habit), status: :created
        else
          render json: { errors: @habit.errors }, status: :unprocessable_entity
        end
      end

      def update
        if @habit.update(habit_params)
          render json: HabitBlueprint.render(@habit)
        else
          render json: { errors: @habit.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        @habit.discard
        head :no_content
      end

      def log_completion
        # Check if already logged today
        existing_log = @habit.habit_logs.where(
          user: current_user,
          logged_date: Date.current
        ).first

        if existing_log
          render json: {
            message: 'Habit already logged for today',
            data: HabitLogBlueprint.render(existing_log)
          }, status: :ok
          return
        end

        habit_log = @habit.habit_logs.build(
          user: current_user,
          logged_date: Date.current,
          completed: true,
          notes: params[:notes]
        )

        if habit_log.save
          render json: {
            message: 'Habit completion logged successfully!',
            data: HabitLogBlueprint.render(habit_log),
            current_streak: @habit.current_streak
          }, status: :created
        else
          render json: { errors: habit_log.errors }, status: :unprocessable_entity
        end
      end

      def toggle_active
        @habit.update!(active: !@habit.active)
        render json: {
          message: "Habit #{@habit.active? ? 'activated' : 'deactivated'}",
          data: HabitBlueprint.render(@habit)
        }
      end

      def streaks
        @habits = policy_scope(Habit).includes(:habit_logs)

        streaks = @habits.map do |habit|
          {
            id: habit.id,
            name: habit.name,
            current_streak: habit.current_streak,
            longest_streak: 0, # TODO: Calculate longest streak from habit_logs
            completion_rate: habit.completion_rate_30_days
          }
        end

        render json: { streaks: streaks }
      end

      # Get habit statistics for the current user
      def stats
        authorize Habit

        stats = {
          total_habits: current_user.habits.count,
          active_habits: current_user.habits.where(active: true).count,
          inactive_habits: current_user.habits.where(active: false).count,
          completed_today: habits_completed_today,
          completion_rate_this_week: completion_rate_this_week,
          best_streak: best_streak_for_user,
          habits_by_frequency: habits_by_frequency_for_user
        }

        render json: stats
      end

      # Get habits dashboard data
      def dashboard
        authorize Habit

        dashboard_data = {
          active_habits: active_habits_for_user,
          todays_progress: todays_progress_for_user,
          weekly_summary: weekly_summary_for_user,
          top_streaks: top_streaks_for_user,
          completion_trends: completion_trends_for_user
        }

        render json: dashboard_data
      end

      # Bulk log habits
      def bulk_log
        authorize Habit

        habit_logs = params[:habits] || []
        created_logs = []
        errors = []

        habit_logs.each do |log_data|
          habit = current_user.habits.find_by(id: log_data[:habit_id])
          next unless habit

          # Check if already logged today
          existing_log = habit.habit_logs.where(
            user: current_user,
            logged_date: Date.current
          ).first

          if existing_log
            errors << { habit_id: habit.id, error: 'Already logged today' }
            next
          end

          habit_log = habit.habit_logs.build(
            user: current_user,
            logged_date: Date.current,
            completed: true,
            notes: log_data[:notes]
          )

          if habit_log.save
            created_logs << habit_log
          else
            errors << { habit_id: habit.id, errors: habit_log.errors }
          end
        end

        if errors.empty?
          render json: {
            message: "#{created_logs.count} habits logged successfully",
            data: HabitLogBlueprint.render(created_logs)
          }
        else
          render json: {
            message: "#{created_logs.count} habits logged, #{errors.count} had errors",
            data: HabitLogBlueprint.render(created_logs),
            errors: errors
          }, status: :partial_content
        end
      end

      # Get habit history
      def history
        @habit = current_user.habits.find(params[:id])
        authorize @habit

        days = (params[:days] || 30).to_i.clamp(1, 365)
        start_date = days.days.ago.to_date

        logs = @habit.habit_logs
          .where(logged_date: start_date..Date.current)
          .order(:logged_date)

        # Create a complete date range with completion status
        history = (start_date..Date.current).map do |date|
          log = logs.find { |l| l.logged_date == date }
          {
            date: date,
            completed: log&.completed || false,
            notes: log&.notes
          }
        end

        render json: {
          habit: HabitBlueprint.render(@habit),
          history: history,
          summary: {
            total_days: history.count,
            completed_days: history.count { |h| h[:completed] },
            completion_rate: (history.count { |h| h[:completed] }.to_f / history.count * 100).round(2)
          }
        }
      end

      private

      def set_habit
        @habit = Habit.find(params[:id])
      end

      def authorize_habit
        authorize @habit
      end

      def habit_params
        params.require(:habit).permit(:name, :description, :frequency, :active)
      end

      def habits_completed_today
        current_user.habit_logs
          .joins(:habit)
          .where(logged_date: Date.current, completed: true)
          .count
      end

      def completion_rate_this_week
        week_start = Date.current.beginning_of_week
        total_possible = current_user.habits.where(active: true).count * 7
        return 0 if total_possible.zero?

        completed = current_user.habit_logs
          .joins(:habit)
          .where(logged_date: week_start..Date.current, completed: true)
          .count

        ((completed.to_f / total_possible) * 100).round(2)
      end

      def best_streak_for_user
        # TODO: Calculate best streak from habit_logs
        0
      end

      def habits_by_frequency_for_user
        current_user.habits.group(:frequency).count
      end

      def active_habits_for_user
        current_user.habits.where(active: true).limit(10)
      end

      def todays_progress_for_user
        active_habits = current_user.habits.where(active: true)
        completed_today = current_user.habit_logs
          .joins(:habit)
          .where(logged_date: Date.current, completed: true)
          .count

        {
          total_active: active_habits.count,
          completed_today: completed_today,
          completion_percentage: active_habits.count.zero? ? 0 : ((completed_today.to_f / active_habits.count) * 100).round(2)
        }
      end

      def weekly_summary_for_user
        week_start = Date.current.beginning_of_week
        daily_completions = current_user.habit_logs
          .joins(:habit)
          .where(logged_date: week_start..Date.current, completed: true)
          .group(:logged_date)
          .count

        (week_start..Date.current).map do |date|
          {
            date: date,
            completions: daily_completions[date] || 0
          }
        end
      end

      def top_streaks_for_user
        current_user.habits
          .where('current_streak > 0')
          .order(current_streak: :desc)
          .limit(5)
          .pluck(:name, :current_streak)
      end

      def completion_trends_for_user
        days = 30
        start_date = days.days.ago.to_date

        daily_completions = current_user.habit_logs
          .joins(:habit)
          .where(logged_date: start_date..Date.current, completed: true)
          .group(:logged_date)
          .count

        (start_date..Date.current).map do |date|
          {
            date: date,
            completions: daily_completions[date] || 0
          }
        end
      end
    end
  end
end
