require "aws-sdk-bedrockruntime"

SYSTEM_PROMPT = <<~PROMPT
  You are a helpful, friendly, and knowledgeable AI assistant. 
  Provide concise responses and maintain a natural conversation flow.
PROMPT

class ChatBot
  def initialize(region: "eu-west-1")
    @client = Aws::BedrockRuntime::Client.new(region: region)
  end

  def send_message(messages)
    body = {
      anthropic_version: "bedrock-2023-05-31",
      max_tokens: 1000,
      system: SYSTEM_PROMPT,
      messages: messages
    }.to_json

    response = @client.invoke_model(
      content_type: "application/json",
      accept: "application/json",
      model_id: "eu.anthropic.claude-3-5-sonnet-20240620-v1:0",
      body: body
    )

    response_body = JSON.parse(response.body.string)
    response_body.dig("content", 0, "text")
  rescue StandardError => e
    "Error: #{e.message}"
  end
end

def main
  chatbot = ChatBot.new
  messages = []

  puts "Claude 3.5 Chat - Type 'exit', 'quit', or 'bye' to end the conversation\n\n"

  loop do
    print "You: "
    input = gets.chomp.strip

    exit_commands = ["exit", "quit", "bye"]
    break if exit_commands.include?(input.downcase)

    next if input.empty?

    messages << { role: "user", content: input }

    print "\nClaude: "
    response = chatbot.send_message(messages)
    puts response

    messages << { role: "assistant", content: response }
    puts "\n"
  end

  puts "\nGoodbye! Have a great day!"
end

main if __FILE__ == $0
