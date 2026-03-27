require "json"
require "net/http"
require "set"
require "uri"

class SeedApiClient
  def initialize(base_url: ENV["SEED_BASE_URL"])
    @base_url = base_url
    @session = base_url.present? ? nil : ActionDispatch::Integration::Session.new(Rails.application)
    @session&.host!("localhost")
  end

  def post(path, payload)
    @base_url.present? ? remote_post(path, payload) : local_post(path, payload)
  end

  private

  def remote_post(path, payload)
    uri = URI.join(@base_url, path)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    request.body = payload.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    [ response.code.to_i, parse_body(response.body) ]
  end

  def local_post(path, payload)
    @session.post(
      path,
      params: payload,
      as: :json
    )

    [ @session.response.status, parse_body(@session.response.body) ]
  end

  def parse_body(body)
    body.present? ? JSON.parse(body) : {}
  rescue JSON::ParserError
    {}
  end
end

class ProjectSeeder
  COMMUNITY_BLUEPRINTS = [
    [ "General", "Open discussion for product updates, daily questions, and the pulse of the platform." ],
    [ "Tech Lab", "Build notes, engineering opinions, debugging wins, and experiments with new stacks." ],
    [ "Design Circle", "Interface critiques, visual references, typography details, and UX tradeoffs." ],
    [ "Growth Room", "Acquisition ideas, retention analysis, campaign review, and conversion lessons." ],
    [ "Support Radar", "Bugs, friction points, customer reports, and what needs attention first." ]
  ].freeze

  USER_PREFIXES = %w[
    amber atlas breeze cedar comet ember fern harbor iris juniper
    kite lunar maple nova orbit pixel quartz river solar terra
  ].freeze

  USER_SUFFIXES = %w[
    fox owl pine wave trail spark bloom echo ember drift field
    forge grove loom mist peak ridge stone vale verse wing
  ].freeze

  POSITIVE_SNIPPETS = [
    "ótimo avanço no fluxo",
    "excelente entrega visual",
    "legal ver esse teste passando",
    "bom progresso na timeline",
    "adorei como a thread ficou clara",
    "incrível como a resposta veio rápida"
  ].freeze

  NEGATIVE_SNIPPETS = [
    "ruim depender de ajuste manual",
    "péssimo quando o loading trava",
    "horrível navegar sem feedback",
    "terrível descobrir o bug só no deploy",
    "odeio quando a validação falha sem contexto"
  ].freeze

  NEUTRAL_SNIPPETS = [
    "precisamos revisar os dados antes da release",
    "o próximo passo é alinhar o seed com o deploy",
    "estou analisando a timeline desta comunidade",
    "vamos medir impacto antes de mudar a regra",
    "esse tópico merece mais exemplos no README"
  ].freeze

  REACTION_TYPES = Reaction::REACTION_TYPES.freeze

  def initialize
    @api = SeedApiClient.new
    @random = Random.new(20260326)
    @message_refs = []
    @communities = []
    @usernames = build_usernames
    @ips = Array.new(20) { |index| "10.24.#{index / 10}.#{(index % 10) + 10}" }
  end

  def run
    reset_data_if_requested
    seed_communities
    seed_messages
    seed_reactions
    print_summary
  end

  private

  def reset_data_if_requested
    return unless ActiveModel::Type::Boolean.new.cast(ENV.fetch("SEED_RESET", "true"))

    puts "Resetting communities, users, messages, and reactions before seeding..."
    Reaction.delete_all
    Message.delete_all
    Community.delete_all
    User.delete_all
  end

  def seed_communities
    @communities = COMMUNITY_BLUEPRINTS.first(community_count).map do |name, description|
      community = Community.find_or_initialize_by(name: name)
      community.description = description
      community.save!
      community
    end
  end

  def seed_messages
    puts "Creating #{root_message_target} root messages via API..."
    root_message_target.times { create_root_message! }

    puts "Creating #{reply_message_target} replies via API..."
    reply_message_target.times { create_reply_message! }
  end

  def seed_reactions
    target_messages = @message_refs.sample(reaction_target_count, random: @random)

    puts "Adding reactions to #{target_messages.size} messages via API..."
    target_messages.each do |message_ref|
      apply_reactions_to!(message_ref)
    end
  end

  def create_root_message!
    community = @communities.sample(random: @random)
    payload = {
      username: @usernames.sample(random: @random),
      community_id: community.id,
      content: build_message_content(community.name),
      user_ip: @ips.sample(random: @random)
    }

    body = post_json!("/api/v1/messages", payload, expected_status: 201)
    ref = {
      id: body.fetch("id"),
      community_id: community.id
    }

    @message_refs << ref
  end

  def create_reply_message!
    parent = @message_refs.sample(random: @random)
    payload = {
      username: @usernames.sample(random: @random),
      community_id: parent.fetch(:community_id),
      content: build_reply_content,
      user_ip: @ips.sample(random: @random),
      parent_message_id: parent.fetch(:id)
    }

    body = post_json!("/api/v1/messages", payload, expected_status: 201)
    @message_refs << {
      id: body.fetch("id"),
      community_id: parent.fetch(:community_id)
    }
  end

  def apply_reactions_to!(message_ref)
    used_pairs = Set.new
    reaction_attempts = @random.rand(1..4)

    reaction_attempts.times do
      username = @usernames.sample(random: @random)
      reaction_type = REACTION_TYPES.sample(random: @random)
      pair = "#{username}:#{reaction_type}"
      next if used_pairs.include?(pair)

      post_json!(
        "/api/v1/reactions",
        {
          message_id: message_ref.fetch(:id),
          username: username,
          reaction_type: reaction_type
        },
        expected_status: 200
      )

      used_pairs << pair
    end

    return if used_pairs.any?

    fallback_username = @usernames.sample(random: @random)
    fallback_type = REACTION_TYPES.sample(random: @random)
    post_json!(
      "/api/v1/reactions",
      {
        message_id: message_ref.fetch(:id),
        username: fallback_username,
        reaction_type: fallback_type
      },
      expected_status: 200
    )
  end

  def build_message_content(community_name)
    snippets = case @random.rand(100)
    when 0..34
      POSITIVE_SNIPPETS
    when 35..59
      NEGATIVE_SNIPPETS
    else
      NEUTRAL_SNIPPETS
    end

    [
      "Community #{community_name}:",
      snippets.sample(random: @random),
      "Thread ##{@random.rand(10_000..99_999)}"
    ].join(" ")
  end

  def build_reply_content
    [
      "Reply follow-up:",
      (POSITIVE_SNIPPETS + NEGATIVE_SNIPPETS + NEUTRAL_SNIPPETS).sample(random: @random),
      "Context #{@random.rand(100..999)}"
    ].join(" ")
  end

  def build_usernames
    usernames = []

    USER_PREFIXES.each do |prefix|
      USER_SUFFIXES.each do |suffix|
        usernames << "#{prefix}_#{suffix}"
        return usernames.first(user_count) if usernames.size >= user_count
      end
    end

    usernames.first(user_count)
  end

  def post_json!(path, payload, expected_status:)
    status, body = @api.post(path, payload)
    return body if status == expected_status

    raise <<~ERROR
      Seed request failed.
      Path: #{path}
      Expected status: #{expected_status}
      Actual status: #{status}
      Payload: #{payload.inspect}
      Response: #{body.inspect}
    ERROR
  end

  def print_summary
    ActiveSupport::ExecutionContext.clear

    puts "Seed completed."
    puts "Communities: #{safe_summary_count { Community.count }}"
    puts "Users: #{safe_summary_count { User.count }}"
    puts "Messages: #{safe_summary_count { Message.count }}"
    puts "Root messages: #{safe_summary_count { Message.where(parent_message_id: nil).count }}"
    puts "Replies: #{safe_summary_count { Message.where.not(parent_message_id: nil).count }}"
    puts "Unique IPs: #{safe_summary_count { Message.distinct.count(:user_ip) }}"
    puts "Messages with reactions: #{safe_summary_count { Message.joins(:reactions).distinct.count }}"
    puts "Reactions: #{safe_summary_count { Reaction.count }}"
  end

  def safe_summary_count
    yield
  rescue StandardError => error
    warn "Summary metric failed: #{error.class} - #{error.message}"
    "unavailable"
  end

  def community_count
    ENV.fetch("SEED_COMMUNITIES", 5).to_i.clamp(1, COMMUNITY_BLUEPRINTS.size)
  end

  def user_count
    ENV.fetch("SEED_USERS", 50).to_i.clamp(1, USER_PREFIXES.size * USER_SUFFIXES.size)
  end

  def root_message_target
    ENV.fetch("SEED_ROOT_MESSAGES", 700).to_i
  end

  def reply_message_target
    ENV.fetch("SEED_REPLY_MESSAGES", 300).to_i
  end

  def reaction_target_count
    ratio = ENV.fetch("SEED_REACTION_RATIO", "0.8").to_f.clamp(0.0, 1.0)
    (@message_refs.size * ratio).round
  end
end

ProjectSeeder.new.run
