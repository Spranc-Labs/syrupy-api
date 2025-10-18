# frozen_string_literal: true

class Api::V1::MoodLogsController < Api::V1::ApiController
  def index
    mood_logs = policy_scope(MoodLog).includes(:user)
                                    .order(logged_at: :desc)
                                    .paginate(page: params[:page], per_page: params[:per_page])
    
    render_page_with_blueprint(
      collection: mood_logs,
      blueprint: MoodLogBlueprint
    )
  end

  def show
    mood_log = MoodLog.find(params[:id])
    authorize(mood_log)
    render json: MoodLogBlueprint.render(mood_log)
  end

  def create
    mood_log = MoodLog.new(mood_log_params)
    authorize(mood_log)
    
    if mood_log.save
      render json: MoodLogBlueprint.render(mood_log), status: :created
    else
      render json: { errors: mood_log.errors }, status: :unprocessable_entity
    end
  end

  def update
    mood_log = MoodLog.find(params[:id])
    authorize(mood_log)
    
    if mood_log.update(mood_log_params)
      render json: MoodLogBlueprint.render(mood_log)
    else
      render json: { errors: mood_log.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    mood_log = MoodLog.find(params[:id])
    authorize(mood_log)
    mood_log.discard
    head :no_content
  end

  def trends
    mood_logs = policy_scope(MoodLog).includes(:user)
    authorize(mood_logs)
    
    # Get mood trends over time (last 30 days)
    trends = mood_logs.where(logged_at: 30.days.ago..Time.current)
                     .group_by_day(:logged_at)
                     .average(:rating)
    
    render json: { trends: trends }
  end

  private

  def mood_log_params
    params.require(:mood_log).permit(:rating, :notes, :logged_at)
          .merge(user: Current.user)
  end
end 