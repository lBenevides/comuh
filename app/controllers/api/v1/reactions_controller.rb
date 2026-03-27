class Api::V1::ReactionsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_message, only: [:create]
  before_action :set_user, only: [:create]

  def create
    return if performed?

    reaction = @message.reactions.build(
      user: @user,
      reaction_type: reaction_params[:reaction_type]
    )

    if reaction.save
      render json: ReactionSerializer.new(@message).as_json, status: :ok
    elsif duplicate_reaction_error?(reaction)
      render json: { errors: reaction.errors.full_messages }, status: :conflict
    else
      render json: { errors: reaction.errors.full_messages }, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    render json: { errors: [I18n.t("api.errors.already_reacted")] }, status: :conflict
  end

  private

  def set_message
    @message = Message.find_by(id: reaction_params[:message_id])

    render json: { error: I18n.t("api.errors.message_not_found") }, status: :not_found unless @message
  end

  def set_user
    @user =
      if reaction_params[:user_id].present?
        User.find_by(id: reaction_params[:user_id])
      elsif reaction_params[:username].present?
        User.find_or_create_by(username: reaction_params[:username])
      end

    if @user&.valid?
      return
    elsif reaction_params[:username].present?
      render json: { errors: @user&.errors&.full_messages || [I18n.t("activerecord.errors.models.user.attributes.username.blank")] }, status: :unprocessable_content
    else
      render json: { error: I18n.t("api.errors.user_not_found") }, status: :not_found
    end
  end

  def reaction_params
    params.permit(:message_id, :user_id, :username, :reaction_type)
  end

  def duplicate_reaction_error?(reaction)
    reaction.errors.of_kind?(:user_id, :taken)
  end
end
