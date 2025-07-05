# ApiController is for all API controllers that expect a user to be authenticated
class ApiController < ApplicationController
  include ActionView::Helpers::NumberHelper

  include Pundit::Authorization
  # For GET requests, we expect to see a policy_scope call used because that scopes down
  # the records that the user is allowed to see. For non-GET requests, we expect to see
  # an authorize call used because that checks that the user is allowed to perform the
  # action on the given record.
  after_action :verify_authorized, if: -> { !request.get? }
  after_action :verify_policy_scoped, if: -> { request.get? }

  def render_page_with_blueprint(collection:, blueprint:, associations: {}, **)
    rendered_items = blueprint.render_with_associations(collection, associations, **)
    render_page(collection:, rendered_items:)
  end

  def render_page(collection:, rendered_items:)
    render json: {
      data: {
        items: rendered_items,
        pages: collection.total_pages,
        total: collection.total_entries,
      },
    }
  end

  def sort_and_paginate(relation:, sort_fields:, default_field:, default_direction: nil)
    sorted = Sort.perform(relation:, sort_fields:, params:, default_field:, default_direction:)
    sorted.paginate(page: params[:page], per_page: params[:per_page])
  end

  before_action :authenticate_user!
  before_action :set_current_user

  private

  def current_user
    return Current.user if Current.user
    
    # JWT token authentication only
    if jwt_token.present?
      payload = JwtService.decode(jwt_token)
      if payload && payload[:account_id] && payload[:type] != 'refresh'
        account = Account.find_by(id: payload[:account_id])
        return Current.user = account&.user if account&.user
      end
    end
    
    nil
  end

  def authenticate_user!
    unless current_user
      render json: {
        success: false,
        message: "Authentication required. Please log in."
      }, status: :unauthorized
    end
  end

  def set_current_user
    Current.user = current_user
  end

  def pundit_user
    current_user
  end

  def jwt_token
    # Extract token from Authorization header
    auth_header = request.headers['Authorization']
    return nil unless auth_header.present?
    
    # Expected format: "Bearer <token>"
    token = auth_header.split(' ').last
    token if token != 'Bearer'
  end
end 