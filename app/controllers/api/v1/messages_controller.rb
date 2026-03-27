class Api::V1::MessagesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_community, only: [ :create ]
  before_action :set_user, only: [ :create ]

  def create
    return if performed?

    @message = Message.new(
      user: @user,
      community: @community,
      content: message_params[:content],
      user_ip: message_params[:user_ip].presence || request.remote_ip,
      parent_message_id: message_params[:parent_message_id]
    )

    @message.ai_sentiment_score = SentimentAnalyzer.call(@message.content)

    if @message.save
      render json: MessageSerializer.new(@message).as_json, status: :created
    else
      render json: { errors: @message.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def message_params
    params.permit(
      :username,
      :community_id,
      :content,
      :user_ip,
      :parent_message_id
    )
  end

  def set_community
    @community = Community.find_by(id: message_params[:community_id])

    render json: { error: I18n.t("api.errors.community_not_found") }, status: :not_found unless @community
  end

  def set_user
    @user = User.find_or_create_by(username: message_params[:username])

    render json: { errors: @user.errors.full_messages }, status: :unprocessable_content unless @user.valid?
  end
end
