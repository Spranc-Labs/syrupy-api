# frozen_string_literal: true

# Migration to add HeyHo account linking fields to users table
# Enables users to connect their HeyHo browser extension for browsing insights
class AddHeyhoLinkingToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :heyho_user_id, :integer
    add_column :users, :heyho_linked_at, :datetime

    add_index :users, :heyho_user_id, unique: true
  end
end
