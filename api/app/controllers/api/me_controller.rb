# frozen_string_literal: true

class Api::MeController < ApiController
  def show
    # TODO: Remove when authentication is fixed - for now return a dummy user
    user = Current.user || User.first || User.new(full_name: "Demo User", email: "demo@example.com")
    render json: UserBlueprint.render(user)
  end

  def update
    user = Current.user || User.first
    if user&.update(user_params)
      render json: UserBlueprint.render(user)
    else
      render json: { errors: user&.errors || { base: ["No user found"] } }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:full_name, :email)
  end
end 