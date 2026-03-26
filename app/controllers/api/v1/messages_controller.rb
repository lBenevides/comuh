class Api::V1::MessagesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_community, only: [:create]
  before_action :set_user, only: [:create]

  def create
   
    
    @message = Message.new(
      user: @user,
      community: @community,
      content: message_params[:content],
      user_ip: message_params[:user_ip],
      parent_message_id: message_params[:parent_message_id]
    )

    @message.ai_sentiment_score = SentimentAnalyzer.call(@message.content)

    if @message.save
      render json: MessageSerializer.new(@message).as_json, status: :created
    else
      render json: @message.errors, status: :unprocessable_entity
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

    render json: { error: "Community not found" }, status: :not_found unless @community
  end
  
  def set_user
    @user = User.find_or_create_by(username: message_params[:username])
  
    render json: { error: @user.errors }, status: :unprocessable_entity unless @user.valid?
  end
end
