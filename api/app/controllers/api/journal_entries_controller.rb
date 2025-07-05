require 'net/http'
require 'uri'
require 'json'

module Api
  class JournalEntriesController < ApiController
    before_action :set_journal_entry, only: [:show, :update, :destroy, :analyze]
    before_action :authorize_journal_entry, only: [:show, :update, :destroy, :analyze]
    skip_after_action :verify_policy_scoped, only: [:ai_service_status, :show]

    def index
      @journal_entries = policy_scope(JournalEntry)
        .includes(:tags, :emotion_label_analysis, :journal_label_analysis)
        .filter_by_text(params[:search])
        .recent
        .paginate(page: params[:page], per_page: 20)

      # Filter by emotion if provided
      if params[:emotion].present?
        @journal_entries = @journal_entries.joins(:emotion_label_analysis)
                                          .where(emotion_label_analyses: { top_emotion: params[:emotion] })
      end

      # Filter by category if provided  
      if params[:category].present?
        @journal_entries = @journal_entries.joins(:journal_label_analysis)
                                          .where("journal_label_analyses.payload->>'category' = ?", params[:category])
      end

      render json: JournalEntryBlueprint.render(@journal_entries, include: [:tags, :emotion_label_analysis, :journal_label_analysis])
    end

    def show
      render json: JournalEntryBlueprint.render(@journal_entry, include: [:tags, :emotion_label_analysis, :journal_label_analysis])
    end

    def create
      @journal_entry = current_user.journal_entries.build(journal_entry_params)
      authorize @journal_entry

      if @journal_entry.save
        # Trigger async analysis if service is available
        AnalyzeJournalEntryJob.perform_later(@journal_entry.id)
        
        render json: JournalEntryBlueprint.render(@journal_entry, include: [:tags]), status: :created
      else
        render json: { errors: @journal_entry.errors }, status: :unprocessable_entity
      end
    end

    def update
      authorize @journal_entry
      
      if @journal_entry.update(journal_entry_params)
        # Re-analyze if content changed
        if @journal_entry.saved_change_to_content? || @journal_entry.saved_change_to_title?
          AnalyzeJournalEntryJob.perform_later(@journal_entry.id)
        end
        
        render json: JournalEntryBlueprint.render(@journal_entry, include: [:tags, :emotion_label_analysis, :journal_label_analysis])
      else
        render json: { errors: @journal_entry.errors }, status: :unprocessable_entity
      end
    end

    def destroy
      @journal_entry.discard
      head :no_content
    end

    def analyze
      # Force re-analysis of the journal entry
      start_time = Time.current
      
      begin
        analysis_result = JournalLabelerService.analyze_journal_entry(
          title: @journal_entry.title,
          content: @journal_entry.content
        )
        
        processing_time = ((Time.current - start_time) * 1000).round(2)
        
        # Create emotion analysis record
        emotion_analysis = @journal_entry.emotion_label_analyses.create!(
          analysis_model: 'journal_labeler',
          model_version: '1.0',
          payload: analysis_result[:emotions] || {},
          top_emotion: analysis_result[:mood_label],
          run_ms: processing_time,
          analyzed_at: Time.current
        )
        
        # Create category analysis record
        journal_analysis = @journal_entry.journal_label_analyses.create!(
          analysis_model: 'journal_labeler',
          model_version: '1.0', 
          payload: {
            category: analysis_result[:category],
            confidence: analysis_result[:category_confidence],
            subcategories: analysis_result[:subcategories] || []
          },
          run_ms: processing_time,
          analyzed_at: Time.current
        )
        
        # Create system tags from analysis
        create_system_tags_from_analysis(@journal_entry, analysis_result)
        
        # Update journal entry with latest analyses
        @journal_entry.update!(
          emotion_label_analysis: emotion_analysis,
          journal_label_analysis: journal_analysis
        )
        
        render json: {
          message: 'Analysis completed successfully',
          data: JournalEntryBlueprint.render(@journal_entry, include: [:tags, :emotion_label_analysis, :journal_label_analysis]),
          processing_time_ms: processing_time
        }
      rescue StandardError => e
        Rails.logger.error "Analysis failed: #{e.message}"
        render json: { error: 'Failed to analyze journal entry', details: e.message }, status: :unprocessable_entity
      end
    end

    def ai_service_status
      status = {
        service_available: JournalLabelerService.health_check,
        available_categories: JournalLabelerService.available_categories,
        timestamp: Time.current.iso8601
      }
      
      render json: status
    end

    # Get emotion statistics for user's journal entries
    def emotion_stats
      authorize JournalEntry
      
      stats = current_user.journal_entries
                         .joins(:emotion_label_analysis)
                         .where.not(emotion_label_analyses: { top_emotion: nil })
                         .group('emotion_label_analyses.top_emotion')
                         .count
      
      render json: { emotion_stats: stats, total_analyzed: stats.values.sum }
    end

    # Get category statistics for user's journal entries
    def category_stats
      authorize JournalEntry
      
      stats = current_user.journal_entries
                         .joins(:journal_label_analysis)
                         .where.not("journal_label_analyses.payload->>'category' IS NULL")
                         .group("journal_label_analyses.payload->>'category'")
                         .count
      
      render json: { category_stats: stats, total_analyzed: stats.values.sum }
    end

    private

    def set_journal_entry
      @journal_entry = JournalEntry.find(params[:id])
    end

    def authorize_journal_entry
      authorize @journal_entry
    end

    def journal_entry_params
      params.permit(:title, :content, tag_ids: [])
    end

    def create_system_tags_from_analysis(journal_entry, analysis)
      return unless analysis

      system_tags_to_create = []
      
      # Add category as a system tag
      if analysis[:category].present?
        system_tags_to_create << {
          name: analysis[:category].humanize.downcase,
          color: category_color(analysis[:category])
        }
      end
      
      # Add subcategories as system tags if they exist
      if analysis[:subcategories]&.any?
        analysis[:subcategories].each do |subcategory|
          system_tags_to_create << {
            name: subcategory.humanize.downcase,
            color: category_color(subcategory)
          }
        end
      end
      
      # Create or find system tags and associate them
      system_tags_to_create.uniq.each do |tag_data|
        tag = Tag.find_or_create_by(
          name: tag_data[:name],
          kind: 'system'
        ) do |new_tag|
          new_tag.color = tag_data[:color]
        end
        
        # Associate the tag with this journal entry if not already associated
        journal_entry.tags << tag unless journal_entry.tags.include?(tag)
      end
    end

    def category_color(category)
      color_map = {
        'personal_growth' => '#10b981',    # green
        'relationships' => '#f59e0b',      # amber
        'work_career' => '#3b82f6',        # blue
        'health_wellness' => '#ef4444',    # red
        'travel_adventure' => '#8b5cf6',   # violet
        'daily_life' => '#6b7280',         # gray
        'emotions_feelings' => '#ec4899',  # pink
        'hobbies_interests' => '#f97316',  # orange
        'spirituality' => '#06b6d4',       # cyan
        'challenges_struggles' => '#7c3aed' # purple
      }
      color_map[category] || '#6b7280'
    end




  end
end