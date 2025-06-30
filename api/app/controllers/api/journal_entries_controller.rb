require 'net/http'
require 'uri'
require 'json'

module Api
  class JournalEntriesController < ApiController
    before_action :set_journal_entry, only: [:show, :update, :destroy, :analyze_ai]
    before_action :authorize_journal_entry, only: [:show, :update, :destroy, :analyze_ai]
    skip_after_action :verify_policy_scoped, only: [:ai_service_status, :show]

    def index
      @journal_entries = policy_scope(JournalEntry)
        .includes(:tags)
        .filter_by_text(params[:search])
        .by_ai_category(params[:ai_category])
        .recent
        .paginate(page: params[:page], per_page: 20)

      render json: JournalEntryBlueprint.render(@journal_entries, include: [:tags])
    end

    def show
      render json: JournalEntryBlueprint.render(@journal_entry, include: [:tags])
    end

    def create
      @journal_entry = current_user.journal_entries.build(journal_entry_params)
      authorize @journal_entry

      if @journal_entry.save
        render json: JournalEntryBlueprint.render(@journal_entry, include: [:tags]), status: :created
      else
        render json: { errors: @journal_entry.errors }, status: :unprocessable_entity
      end
    end

    def update
      authorize @journal_entry
      if @journal_entry.update(journal_entry_params)
        render json: JournalEntryBlueprint.render(@journal_entry, include: [:tags])
      else
        render json: { errors: @journal_entry.errors }, status: :unprocessable_entity
      end
    end

    def destroy
      @journal_entry.discard
      head :no_content
    end

    def analyze_ai
      if @journal_entry.analyze_with_ai!
        render json: JournalEntryBlueprint.render(@journal_entry, include: [:tags])
      else
        render json: { error: 'Failed to analyze journal entry' }, status: :unprocessable_entity
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

    private

    def set_journal_entry
      @journal_entry = JournalEntry.find(params[:id])
    end

    def authorize_journal_entry
      authorize @journal_entry
    end

    def journal_entry_params
      params.permit(:title, :content, :mood_rating, tag_ids: [])
    end
  end
end