require "aws-sdk-bedrockruntime"

SYSTEM_PROMPT = <<~PROMPT
  You are a helpful, friendly, and knowledgeable AI assistant. 
  Provide concise responses and maintain a natural conversation flow.
PROMPT

class ChatBot
  def initialize(region: "eu-west-1")
    @client = Aws::BedrockRuntime::Client.new(region: region)
    @model_id = "eu.anthropic.claude-3-5-sonnet-20240620-v1:0"
    
    @conversation = []

    @system_prompts = [{ text: SYSTEM_PROMPT }]

    @inference_config = {
      max_tokens: 1000,
      temperature: 1.0
    }
  end

  def send_message(user_input)
    @conversation << {
      role: "user",
      content: [{ text: user_input }]
    }

    response = @client.converse(
      model_id: @model_id,
      messages: @conversation,
      system: @system_prompts,
      inference_config: @inference_config
    )

    assistant_text = response["output"]["message"]["content"][0]["text"]

    @conversation << {
      role: "assistant",
      content: [{ text: assistant_text }]
    }

    assistant_text
  rescue StandardError => e
    "Error: #{e.message}"
  end
end

def main
  chatbot = ChatBot.new
  puts "Claude 3.5 Chat - Type 'exit', 'quit', or 'bye' to end the conversation\n\n"

  loop do
    print "You: "
    input = gets.chomp.strip

    exit_commands = ["exit", "quit", "bye"]
    break if exit_commands.include?(input.downcase)

    next if input.empty?

    response = chatbot.send_message(input)

    print "\nClaude: "
    puts response
    puts "\n"
  end

  puts "\nGoodbye! Have a great day!"
end

main if __FILE__ == $0
