require "test_helper"
require "action_cable/channel/test_case"

class AnalysisChannelTest < ActionCable::Channel::TestCase
  tests AnalysisChannel

  setup do
    @analysis = Analysis.create!(kind: "text", status: "pending")
  end

  test "subscribes to the analysis model stream" do
    subscribe analysis_id: @analysis.id

    assert subscription.confirmed?
    assert_has_stream_for @analysis
  end

  test "rejects subscriptions for unknown analyses" do
    subscribe analysis_id: -1

    assert subscription.rejected?
  end

  test "broadcast_to publishes to the model stream" do
    assert_broadcast_on(@analysis, event: "analysis_delta", delta: "hello") do
      AnalysisChannel.broadcast_to(@analysis, event: "analysis_delta", delta: "hello")
    end
  end
end
