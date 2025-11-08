# frozen_string_literal: true

class JournalEntryTag < ActiveRecord::Base
  belongs_to :journal_entry
  belongs_to :tag

  validates :journal_entry_id, uniqueness: { scope: :tag_id }
end
