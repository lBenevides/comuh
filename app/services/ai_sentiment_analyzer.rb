require "json"
require "net/http"
require "uri"

class AISentimentAnalyzer
  ENDPOINT = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent")
  PROMPT = <<~TEXT.freeze
    Você analisa o sentimento de mensagens curtas publicadas em uma comunidade online.
    Retorne apenas um número decimal entre -1.0 e 1.0.
    - -1.0 representa sentimento muito negativo
    - 0.0 representa sentimento neutro
    - 1.0 representa sentimento muito positivo
    Considere tom, intensidade e contexto da mensagem.
  TEXT

  def self.call(message)
    new.call(message)
  end

  def initialize(api_key: default_api_key, http_client: Net::HTTP)
    @api_key = api_key
    @http_client = http_client
  end

  def call(message)
    normalize_score(extract_score(message.to_s))
  end

  private

  attr_reader :api_key, :http_client

  def extract_score(message)
    response = http_client.post(
      ENDPOINT,
      request_body(message),
      request_headers
    )

    raise_request_error(response) unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    content = body.dig("candidates", 0, "content", "parts", 0, "text").to_s
    score = content[/\-?\d+(?:\.\d+)?/]

    raise "No sentiment score returned" if score.nil?

    score
  end

  def normalize_score(score)
    score.to_f.clamp(-1.0, 1.0).round(2)
  end

  def request_body(message)
    {
      contents: [
        {
          parts: [
            {
              text: "#{PROMPT}\n\nMensagem: #{message}"
            }
          ]
        }
      ],
      generationConfig: {
        temperature: 0
      }
    }.to_json
  end

  def request_headers
    {
      "Content-Type" => "application/json",
      "x-goog-api-key" => api_key
    }
  end

  def raise_request_error(response)
    body = response.body.to_s
    raise "Gemini request failed with status #{response.code}: #{body}"
  end

  def self.default_api_key
    ENV.fetch("GEMINI_API_KEY")
  end

  def default_api_key
    self.class.default_api_key
  end
end
