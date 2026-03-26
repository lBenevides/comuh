class Api::V1::ReactionsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_message, only: [:create]
  before_action :set_user, only: [:create]

  def create
    #return if performed?

    reaction = @message.reactions.build(
      user: @user,
      reaction_type: reaction_params[:reaction_type]
    )

    if reaction.save
      render json: ReactionSerializer.new(@message).as_json, status: :ok
    else
      render json: { errors: reaction.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    render json: { errors: ["User has already added this reaction to this message"] }, status: :conflict
  end

  private

  def set_message
    @message = Message.find_by(id: reaction_params[:message_id])

    render json: { error: "Message not found" }, status: :not_found unless @message
  end

  def set_user
    @user = User.find_by(id: reaction_params[:user_id])

    render json: { error: "User not found" }, status: :not_found unless @user
  end

  def reaction_params
    params.permit(:message_id, :user_id, :reaction_type)
  end
end
