# frozen_string_literal: true

module Api
  module V1
    class GoalsController < ApiController
      before_action :set_goal, only: [:show, :update, :destroy, :mark_completed, :mark_in_progress]
      before_action :authorize_goal, only: [:show, :update, :destroy, :mark_completed, :mark_in_progress]
      skip_after_action :verify_policy_scoped, only: [:stats, :dashboard, :bulk_update]

      def index
        @goals = policy_scope(Goal)
          .includes(:user)
          .filter_by_text(params[:q])

        @goals = @goals.by_status(params[:status]) if params[:status].present?
        @goals = @goals.by_priority(params[:priority]) if params[:priority].present?

        # Filter by due date
        if params[:due_soon].present?
          @goals = @goals.where('target_date <= ?', 7.days.from_now)
        end

        # Filter by date range
        if params[:start_date].present? && params[:end_date].present?
          @goals = @goals.where(
            target_date: Date.parse(params[:start_date])..Date.parse(params[:end_date])
          )
        end

        @goals = @goals
          .order(:target_date, :created_at)
          .paginate(page: params[:page], per_page: params[:per_page] || 20)

        render json: GoalBlueprint.render(@goals)
      end

      def show
        render json: GoalBlueprint.render(@goal)
      end

      def create
        @goal = current_user.goals.build(goal_params)
        authorize @goal

        if @goal.save
          render json: GoalBlueprint.render(@goal), status: :created
        else
          render json: { errors: @goal.errors }, status: :unprocessable_entity
        end
      end

      def update
        if @goal.update(goal_params)
          render json: GoalBlueprint.render(@goal)
        else
          render json: { errors: @goal.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        @goal.discard
        head :no_content
      end

      def mark_completed
        if @goal.update(status: 'completed')
          render json: {
            message: 'Goal marked as completed!',
            data: GoalBlueprint.render(@goal)
          }
        else
          render json: { errors: @goal.errors }, status: :unprocessable_entity
        end
      end

      def mark_in_progress
        if @goal.update(status: 'in_progress')
          render json: {
            message: 'Goal marked as in progress!',
            data: GoalBlueprint.render(@goal)
          }
        else
          render json: { errors: @goal.errors }, status: :unprocessable_entity
        end
      end

      # Get goal statistics for the current user
      def stats
        authorize Goal

        stats = {
          total_goals: current_user.goals.count,
          completed_goals: current_user.goals.where(status: 'completed').count,
          in_progress_goals: current_user.goals.where(status: 'in_progress').count,
          pending_goals: current_user.goals.where(status: 'pending').count,
          overdue_goals: current_user.goals.where('target_date < ? AND status != ?', Date.current, 'completed').count,
          completion_rate: completion_rate_for_user,
          recent_completions: recent_completions_for_user
        }

        render json: stats
      end

      # Get goals dashboard data
      def dashboard
        authorize Goal

        dashboard_data = {
          upcoming_goals: upcoming_goals_for_user,
          overdue_goals: overdue_goals_for_user,
          recent_completions: recent_completions_for_user,
          goals_by_priority: goals_by_priority_for_user,
          goals_by_status: goals_by_status_for_user
        }

        render json: dashboard_data
      end

      # Bulk update goals
      def bulk_update
        authorize Goal

        goal_updates = params[:goals] || []
        updated_goals = []
        errors = []

        goal_updates.each do |goal_data|
          goal = current_user.goals.find_by(id: goal_data[:id])
          next unless goal

          if goal.update(goal_data.permit(:status, :priority, :target_date))
            updated_goals << goal
          else
            errors << { id: goal.id, errors: goal.errors }
          end
        end

        if errors.empty?
          render json: {
            message: "#{updated_goals.count} goals updated successfully",
            data: GoalBlueprint.render(updated_goals)
          }
        else
          render json: {
            message: "#{updated_goals.count} goals updated, #{errors.count} had errors",
            data: GoalBlueprint.render(updated_goals),
            errors: errors
          }, status: :partial_content
        end
      end

      private

      def set_goal
        @goal = Goal.find(params[:id])
      end

      def authorize_goal
        authorize @goal
      end

      def goal_params
        params.permit(:title, :description, :status, :priority, :target_date)
      end

      def completion_rate_for_user
        total = current_user.goals.count
        return 0 if total.zero?

        completed = current_user.goals.where(status: 'completed').count
        ((completed.to_f / total) * 100).round(2)
      end

      def recent_completions_for_user
        current_user.goals
          .where(status: 'completed')
          .where('updated_at >= ?', 30.days.ago)
          .order(updated_at: :desc)
          .limit(5)
          .pluck(:title, :updated_at)
      end

      def upcoming_goals_for_user
        current_user.goals
          .where('target_date >= ? AND target_date <= ?', Date.current, 7.days.from_now)
          .where.not(status: 'completed')
          .order(:target_date)
          .limit(5)
      end

      def overdue_goals_for_user
        current_user.goals
          .where('target_date < ?', Date.current)
          .where.not(status: 'completed')
          .order(:target_date)
          .limit(5)
      end

      def goals_by_priority_for_user
        current_user.goals
          .group(:priority)
          .count
      end

      def goals_by_status_for_user
        current_user.goals
          .group(:status)
          .count
      end
    end
  end
end
