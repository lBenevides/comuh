class CommunitiesController < ApplicationController
  before_action :set_community, only: :show

  def index
    @communities = Community
      .left_joins(:messages)
      .select("communities.*, COUNT(messages.id) AS messages_count")
      .group("communities.id")
      .order("communities.name ASC")
  end

  def show
    @messages = @community.messages
      .where(parent_message_id: nil)
      .includes(:user, :reactions, :replies)
      .order(created_at: :desc)
      .limit(50)

    @new_message = Message.new
  end

  private

  def set_community
    @community = Community.find(params[:id])
  end
end
