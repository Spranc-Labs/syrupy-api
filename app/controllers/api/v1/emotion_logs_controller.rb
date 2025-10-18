# frozen_string_literal: true

module Api
  module V1
    class EmotionLogsController < ApiController
      before_action :set_emotion_log, only: [:show, :update, :destroy]
      before_action :authorize_emotion_log, only: [:show, :update, :destroy]
      skip_after_action :verify_policy_scoped, only: [:stats, :trends, :quick_log]

      def index
        @emotion_logs = policy_scope(EmotionLog)
                        .includes(:user)
                        .recent

        # Filter by emotion if provided
        @emotion_logs = @emotion_logs.by_emotion(params[:emotion]) if params[:emotion].present?

        # Filter by date range if provided
        if params[:start_date].present? && params[:end_date].present?
          @emotion_logs = @emotion_logs.by_date_range(
            Date.parse(params[:start_date]),
            Date.parse(params[:end_date])
          )
        elsif params[:period].present?
          case params[:period]
          when 'today'
            @emotion_logs = @emotion_logs.today
          when 'week'
            @emotion_logs = @emotion_logs.this_week
          when 'month'
            @emotion_logs = @emotion_logs.this_month
          end
        end

        @emotion_logs = @emotion_logs.paginate(page: params[:page], per_page: 50)

        render json: EmotionLogBlueprint.render(@emotion_logs)
      end

      def show
        render json: EmotionLogBlueprint.render(@emotion_log)
      end

      def create
        @emotion_log = current_user.emotion_logs.build(emotion_log_params)
        authorize @emotion_log

        if @emotion_log.save
          render json: EmotionLogBlueprint.render(@emotion_log), status: :created
        else
          render json: { errors: @emotion_log.errors }, status: :unprocessable_entity
        end
      end

      def update
        if @emotion_log.update(emotion_log_params)
          render json: EmotionLogBlueprint.render(@emotion_log)
        else
          render json: { errors: @emotion_log.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        @emotion_log.discard
        head :no_content
      end

      # Get emotion statistics for the current user
      def stats
        authorize EmotionLog

        stats = {
          total_logs: current_user.emotion_logs.count,
          this_week: current_user.emotion_logs.this_week.count,
          this_month: current_user.emotion_logs.this_month.count,
          most_common_emotion: most_common_emotion_for_user,
          emotion_distribution: emotion_distribution_for_user,
          recent_streak: recent_streak_for_user
        }

        render json: stats
      end

      # Quick emotion check-in endpoint
      def quick_log
        authorize EmotionLog

        @emotion_log = current_user.emotion_logs.build(
          emotion_label: params[:emotion],
          emoji: emotion_to_emoji(params[:emotion]),
          captured_at: Time.current,
          note: params[:note]
        )

        if @emotion_log.save
          render json: {
            message: 'Emotion logged successfully',
            data: EmotionLogBlueprint.render(@emotion_log)
          }, status: :created
        else
          render json: { errors: @emotion_log.errors }, status: :unprocessable_entity
        end
      end

      # Get emotion trends over time
      def trends
        authorize EmotionLog

        days = (params[:days] || 30).to_i.clamp(1, 365)
        start_date = days.days.ago.beginning_of_day

        daily_emotions = current_user.emotion_logs
                                     .where(captured_at: start_date..Time.current)
                                     .group('DATE(captured_at)')
                                     .group(:emotion_label)
                                     .count

        # Transform data for charting
        trends_data = {}
        daily_emotions.each do |(date, emotion), count|
          trends_data[date] ||= {}
          trends_data[date][emotion] = count
        end

        render json: {
          trends: trends_data,
          period: "#{days} days",
          start_date: start_date.to_date,
          end_date: Date.current
        }
      end

      private

      def set_emotion_log
        @emotion_log = EmotionLog.find(params[:id])
      end

      def authorize_emotion_log
        authorize @emotion_log
      end

      def emotion_log_params
        params.permit(:emotion_label, :emoji, :note, :captured_at)
      end

      def most_common_emotion_for_user
        current_user.emotion_logs
                    .group(:emotion_label)
                    .count
                    .max_by(&:last)
                    &.first
      end

      def emotion_distribution_for_user
        current_user.emotion_logs
                    .group(:emotion_label)
                    .count
      end

      def recent_streak_for_user
        # Calculate how many consecutive days user has logged emotions
        recent_logs = current_user.emotion_logs
                                  .where('captured_at >= ?', 30.days.ago)
                                  .group('DATE(captured_at)')
                                  .count

        streak = 0
        date = Date.current

        while recent_logs[date.to_s].present?
          streak += 1
          date = date.yesterday
        end

        streak
      end

      def emotion_to_emoji(emotion)
        mood_emojis = {
          'happy' => '😊',
          'sad' => '😢',
          'angry' => '😠',
          'fearful' => '😨',
          'surprised' => '😲',
          'disgusted' => '🤢',
          'neutral' => '😐',
          'excited' => '🤩',
          'anxious' => '😰',
          'grateful' => '🙏',
          'frustrated' => '😤',
          'content' => '😌',
          'overwhelmed' => '😵',
          'peaceful' => '☮️',
          'lonely' => '😔'
        }

        mood_emojis[emotion] || '😐'
      end
    end
  end
end
