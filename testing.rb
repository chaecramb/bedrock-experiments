require "rspec"
require "aws-sdk-bedrockruntime"

RSpec.describe "BedrockChatbot" do
  it "stubs a single converse call" do
    bedrock_client = Aws::BedrockRuntime::Client.new(stub_responses: true)

    bedrock_client.stub_responses(
      :converse, 
      {
        output: {
          message: {
            role: "assistant",
            content: [
              { text: "Hello from stub" }
            ]
          },
        },
        stop_reason: 'end_turn',
        usage: {
          input_tokens: 10,
          output_tokens: 20,
          total_tokens: 30
        },
        metrics: {
          latency_ms: 999
        }
      })

    response = bedrock_client.converse(
      model_id: "my-model-id",
      messages: [
        {
          role: "user",
          content: [ { text: "Hello Bedrock" } ]
        }
      ]
    )

    expect(response.output.message.role).to eq("assistant")
    expect(response.output.message.content.first.text).to eq("Hello from stub")
    expect(response.stop_reason).to eq("end_turn")
    expect(response.usage.total_tokens).to eq(30)
    expect(response.metrics.latency_ms).to eq(999)
  end
end
