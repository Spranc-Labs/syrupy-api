class CreateRodauth < ActiveRecord::Migration[7.1]
  def change
    enable_extension "citext"

    # Used by the account verification and close account features
    create_table :accounts do |t|
      t.integer :status, null: false, default: 1
      t.citext :email, null: false
      t.index :email, unique: true, where: "status IN (1, 2)"
    end

    # Used by the password authentication feature
    create_table :account_password_hashes do |t|
      t.foreign_key :accounts, column: :id
      t.string :password_hash, null: false
    end

    # Used by the login feature
    create_table :account_login_failures do |t|
      t.foreign_key :accounts, column: :id
      t.integer :number, null: false, default: 1
    end

    # Used by the lockout feature
    create_table :account_lockouts do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :deadline, null: false
    end

    # Used by the active sessions feature
    create_table :account_active_session_keys do |t|
      t.references :account, foreign_key: true
      t.string :session_id
      t.datetime :created_at, null: false
      t.datetime :last_use, null: false
      t.index [:session_id]
      t.index [:account_id, :session_id]
    end

    # Used by the account verification feature
    create_table :account_verification_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :requested_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :email_last_sent, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    # Used by the verify login change feature
    create_table :account_login_change_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.string :login, null: false
      t.datetime :deadline, null: false
    end

    # Used by the reset password feature
    create_table :account_password_reset_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :deadline, null: false
      t.datetime :email_last_sent, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    # Used by the verify account feature
    create_table :account_remember_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :deadline, null: false
    end
  end
end 