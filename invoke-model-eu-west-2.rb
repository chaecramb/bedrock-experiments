require 'aws-sdk-bedrockruntime'

client = Aws::BedrockRuntime::Client.new(region: "eu-west-2")

model_id = "anthropic.claude-3-sonnet-20240229-v1:0"

prompt = "Describe the purpose of a 'hello world' program in one line."

native_request = {
  anthropic_version: "bedrock-2023-05-31",
  max_tokens: 1000,
  messages: [
    {
      role: "user",
      content: [
        {
          type: "text",
          text: prompt
        }
      ]
    }
  ]
}

begin
  response = client.invoke_model(
    model_id: model_id,
    body: JSON.generate(native_request)
  )
rescue Aws::Errors::ServiceError => e
  puts "ERROR: Can't invoke '#{model_id}'. Reason: #{e}"
  exit(1)
end

model_response = JSON.parse(response.body.read)

response_text = model_response["content"][0]["text"]
puts response_text
