class MessagesController < ApplicationController
  before_action :set_message, only: :show

  def show
    @replies = @message.replies.includes(:user, :reactions, replies: :user).order(created_at: :asc)
    @reply = Message.new
  end

  def create
    @community = Community.find_by(id: message_params[:community_id])

    unless @community
      redirect_back fallback_location: root_path, alert: I18n.t("api.errors.community_not_found")
      return
    end

    user = User.find_or_create_by(username: message_params[:username])

    unless user.valid?
      redirect_to redirect_path_for(message_params[:parent_message_id]), alert: user.errors.full_messages.to_sentence
      return
    end

    @message = Message.new(
      user: user,
      community: @community,
      content: message_params[:content],
      user_ip: request.remote_ip,
      parent_message_id: message_params[:parent_message_id].presence
    )

    @message.ai_sentiment_score = SentimentAnalyzer.call(@message.content)

    if @message.save
      respond_to do |format|
        format.turbo_stream { head :ok }
        format.html { redirect_to redirect_path_for(@message), notice: t("messages.composer.status.success") }
      end
    else
      redirect_to redirect_path_for(@message), alert: @message.errors.full_messages.to_sentence
    end
  end

  private

  def set_message
    @message = Message.includes(:user, :reactions, replies: [ :user, :reactions ]).find(params[:id])
  end

  def message_params
    params.permit(:username, :community_id, :content, :parent_message_id)
  end

  def redirect_path_for(message)
    if message.parent_message_id.present?
      message_path(message.parent_message_id)
    else
      community_path(@community)
    end
  end
end
