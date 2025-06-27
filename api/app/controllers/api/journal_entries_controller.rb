module Api
  class JournalEntriesController < ApiController
    def index
      journal_entries = policy_scope(JournalEntry)
        .includes(:tags, :user)
        .filter_by_text(params[:q])

      if params[:mood_min].present? && params[:mood_max].present?
        journal_entries = journal_entries.by_mood_range(params[:mood_min], params[:mood_max])
      end

      if params[:start_date].present? && params[:end_date].present?
        journal_entries = journal_entries.by_date_range(
          Date.parse(params[:start_date]),
          Date.parse(params[:end_date])
        )
      end

      journal_entries = journal_entries
        .recent
        .paginate(page: params[:page], per_page: params[:per_page])

      associations = { tags: {}, user: {} }
      render_page_with_blueprint(collection: journal_entries, blueprint: JournalEntryBlueprint, associations:)
    end

    def show
      journal_entry = policy_scope(JournalEntry).find(params[:id])
      associations = { tags: {}, user: {} }

      render json: { data: JournalEntryBlueprint.render_with_associations(journal_entry, associations) }
    end

    def create
      authorize(JournalEntry)

      journal_entry = JournalEntry.new(journal_entry_params)
      journal_entry.user = Current.user
      journal_entry.save!

      # Handle tags
      if params[:tag_ids].present?
        tag_ids = params[:tag_ids].reject(&:blank?)
        journal_entry.tag_ids = tag_ids
      end

      render json: { data: JournalEntryBlueprint.render_as_hash(journal_entry) }, status: :created
    end

    def update
      journal_entry = JournalEntry.find(params[:id])
      authorize(journal_entry)

      journal_entry.update!(journal_entry_params)

      # Handle tags
      if params[:tag_ids].present?
        tag_ids = params[:tag_ids].reject(&:blank?)
        journal_entry.tag_ids = tag_ids
      end

      render json: { data: JournalEntryBlueprint.render_as_hash(journal_entry) }
    end

    def destroy
      journal_entry = JournalEntry.find(params[:id])
      authorize(journal_entry)
      journal_entry.discard!
      head :no_content
    end

    private

    def journal_entry_params
      params.permit(:title, :content, :mood_rating)
    end
  end
end