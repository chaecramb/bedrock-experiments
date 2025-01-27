require "aws-sdk-bedrockruntime"

client = Aws::BedrockRuntime::Client.new(region: "eu-west-1")

model_id = "eu.anthropic.claude-3-5-sonnet-20240620-v1:0"

user_message = "Describe the purpose of a 'hello world' program in one line."

conversation = [
  {
    role: "user",
    content: [{text: user_message}]
  }
]

inference_config = {
  max_tokens: 1000,
  temperature: 1.0,
}

begin
  response = client.converse(
    model_id: model_id,
    messages: conversation,
    inference_config: inference_config
  )
rescue Aws::Errors::ServiceError => e
  puts "ERROR: Can't invoke '#{model_id}'. Reason: #{e}"
  exit(1)
end

response_text = response["output"]["message"]["content"][0]["text"]
puts response_text
