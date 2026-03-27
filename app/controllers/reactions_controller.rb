class ReactionsController < ApplicationController
  def create
    @message = Message.includes(:community).find_by(id: reaction_params[:message_id])

    unless @message
      redirect_back fallback_location: root_path, alert: I18n.t("api.errors.message_not_found")
      return
    end

    user = User.find_or_create_by(username: reaction_params[:username])

    unless user.valid?
      redirect_to redirect_path, alert: user.errors.full_messages.to_sentence
      return
    end

    reaction = @message.reactions.build(
      user: user,
      reaction_type: reaction_params[:reaction_type]
    )

    if reaction.save
      respond_to do |format|
        format.turbo_stream { head :ok }
        format.html { redirect_to redirect_path, notice: t("messages.reactions.status.success") }
      end
    elsif reaction.errors.of_kind?(:user_id, :taken)
      redirect_to redirect_path, alert: I18n.t("api.errors.already_reacted")
    else
      redirect_to redirect_path, alert: reaction.errors.full_messages.to_sentence
    end
  rescue ActiveRecord::RecordNotUnique
    redirect_to redirect_path, alert: I18n.t("api.errors.already_reacted")
  end

  private

  def reaction_params
    params.permit(:message_id, :username, :reaction_type, :context)
  end

  def redirect_path
    if reaction_params[:context] == "thread"
      message_path(@message)
    else
      community_path(@message.community)
    end
  end
end
