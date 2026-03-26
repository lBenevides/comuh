class MessagesController < ApplicationController
  before_action :set_message, only: :show

  def show
    @replies = @message.replies.includes(:user, :reactions, replies: :user).order(created_at: :asc)
    @reply = Message.new
  end

  private

  def set_message
    @message = Message.includes(:user, :reactions, replies: [:user, :reactions]).find(params[:id])
  end
end
