# frozen_string_literal: true

class Api::V1::AuthController < Api::V1::ApiController
  skip_before_action :authenticate_user!, only: [:register, :login, :refresh]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  # POST /api/auth/register
  def register
    @account = Account.new(account_params)
    
    if @account.save
      @user = User.create!(
        account: @account,
        first_name: params[:first_name],
        last_name: params[:last_name],
        email: params[:email]
      )
      
      # Auto-login after registration
      access_token = JwtService.encode(account_id: @account.id)
      refresh_token = JwtService.encode_refresh_token(account_id: @account.id)
      Current.user = @user
      
      render json: {
        success: true,
        message: "Account created successfully",
        user: UserBlueprint.render_as_hash(@user),
        access_token: access_token,
        refresh_token: refresh_token
      }, status: :created
    else
      render json: {
        success: false,
        errors: @account.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/auth/login
  def login
    @account = Account.find_by(email: params[:email]&.downcase)
    
    if @account&.authenticate(params[:password])
      access_token = JwtService.encode(account_id: @account.id)
      refresh_token = JwtService.encode_refresh_token(account_id: @account.id)
      Current.user = @account.user
      
      render json: {
        success: true,
        message: "Logged in successfully",
        user: UserBlueprint.render_as_hash(@account.user),
        access_token: access_token,
        refresh_token: refresh_token
      }
    else
      render json: {
        success: false,
        message: "Invalid email or password"
      }, status: :unauthorized
    end
  end

  # DELETE /api/auth/logout
  def logout
    session[:account_id] = nil
    Current.user = nil
    
    render json: {
      success: true,
      message: "Logged out successfully"
    }
  end

  # GET /api/auth/me
  def me
    if current_user
      render json: {
        success: true,
        user: UserBlueprint.render_as_hash(current_user)
      }
    else
      render json: {
        success: false,
        message: "Not authenticated"
      }, status: :unauthorized
    end
  end

  # POST /api/auth/refresh
  def refresh
    refresh_token = params[:refresh_token]
    
    if refresh_token.blank?
      render json: {
        success: false,
        message: "Refresh token is required"
      }, status: :bad_request
      return
    end

    new_access_token = JwtService.refresh_access_token(refresh_token)
    
    if new_access_token
      render json: {
        success: true,
        access_token: new_access_token
      }
    else
      render json: {
        success: false,
        message: "Invalid or expired refresh token"
      }, status: :unauthorized
    end
  end

  private

  def account_params
    {
      email: params[:email]&.downcase,
      password: params[:password],
      status: Account::Status::VERIFIED
    }
  end


end 