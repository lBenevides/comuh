class Api::V1::AnalyticsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def suspicious_ips
    suspicious_ip_rows = Message
      .joins(:user)
      .where(user_ip: suspicious_ip_usernames.keys)
      .group(:user_ip)
      .having("COUNT(DISTINCT messages.user_id) >= ?", min_users_param)
      .pluck(
        :user_ip,
        Arel.sql("COUNT(DISTINCT messages.user_id)")
      )

    suspicious_ips = suspicious_ip_rows.map do |ip, user_count|
      {
        ip: ip,
        user_count: user_count,
        usernames: suspicious_ip_usernames.fetch(ip)
      }
    end

    render json: SuspiciousIpsSerializer.new(suspicious_ips).as_json, status: :ok
  end

  private

  def min_users_param
    requested_min_users = params[:min_users].presence&.to_i || 3

    [ requested_min_users, 1 ].max
  end

  def suspicious_ip_usernames
    @suspicious_ip_usernames ||= Message
      .joins(:user)
      .group_by(&:user_ip)
      .transform_values do |messages|
        messages.map { |message| message.user.username }.uniq.sort
      end
  end
end
