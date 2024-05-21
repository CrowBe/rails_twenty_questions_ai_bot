class ChatService
  attr_reader :message

  def initialize(initial_prompt:)
    @initial_prompt = initial_prompt
  end

  def system_prompt
    { role: "system", content: @initial_prompt}
  end

  # chat_history: {role: "system" | "user" | "assistant", content: string}[]
  def call(chat_history:)
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo-0125",
        messages: chat_history,
        temperature: 0.7,
      }
    )

    response.dig("choices", 0, "message", "content")
  end

  private

  def client
    @_client ||= OpenAI::Client.new(access_token: Rails.application.credentials.open_ai_api_key)
  end
end