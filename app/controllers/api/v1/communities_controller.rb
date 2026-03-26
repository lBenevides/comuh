class Api::V1::CommunitiesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_community, only: [:top]

  def top
    messages = @community.messages
      .includes(:user)
      .left_joins(:reactions, :replies)
      .select(
        "messages.*",
        "COUNT(DISTINCT reactions.id) AS reaction_count",
        "COUNT(DISTINCT replies_messages.id) AS reply_count",
        "(COUNT(DISTINCT reactions.id) * 1.5 + COUNT(DISTINCT replies_messages.id) * 1.0) AS engagement_score"
      )
      .group("messages.id")
      .order(Arel.sql("engagement_score DESC, messages.created_at DESC"))
      .limit(limit_param)

    render json: CommunityTopMessagesSerializer.new(messages).as_json, status: :ok
  end

  private

  def set_community
    @community = Community.find_by(id: params[:id])

    render json: { error: I18n.t("api.errors.community_not_found") }, status: :not_found unless @community
  end

  def limit_param
    requested_limit = params[:limit].presence&.to_i || 10

    [[requested_limit, 1].max, 50].min
  end
end
