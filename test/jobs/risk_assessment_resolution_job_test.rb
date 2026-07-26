require "test_helper"

class RiskAssessmentResolutionJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  FakeMessage = Data.define(:content)
  FakeChoice = Data.define(:message)
  FakeResponse = Data.define(:choices)

  class FakeCompletions
    attr_reader :requests

    def initialize
      @requests = []
    end

    def create(**params)
      @requests << params
      FakeResponse.new([ FakeChoice.new(FakeMessage.new("resource \"example\" \"secure\" {}")) ])
    end
  end

  class FakeChat
    attr_reader :completions

    def initialize(completions)
      @completions = completions
    end
  end

  class FakeClient
    attr_reader :chat

    def initialize(completions)
      @chat = FakeChat.new(completions)
    end
  end

  test "generates attached artifacts only for high and critical findings" do
    analysis = Analysis.create!(kind: "text", status: "completed", result: "done")
    export = analysis.create_analysis_export!(format: "json")
    export.file.attach(
      io: StringIO.new(JSON.generate(
        "architecture_summary" => "AWS application",
        "spoofing" => [
          { "explanation" => "Public role", "resolution" => "Restrict IAM", "impact_category" => "Critical" },
          { "explanation" => "Minor issue", "resolution" => "Document", "impact_category" => "Low" }
        ],
        "tampering" => [
          { "explanation" => "Mutable image", "resolution" => "Pin digest", "impact_category" => "HIGH" }
        ]
      )),
      filename: "analysis.json",
      content_type: "application/json"
    )
    completions = FakeCompletions.new
    job = RiskAssessmentResolutionJob.new
    fake_client = FakeClient.new(completions)
    events = []
    job.define_singleton_method(:client) { fake_client }
    job.define_singleton_method(:broadcast) { |_analysis, payload| events << payload }
    job.perform(export.id)

    assert_equal %w[resolutions_started resolutions_completed], events.pluck(:event)
    assert_equal 2, events.last[:resolutions].size
    assert_equal 2, export.risk_assessment_resolutions.count
    assert_equal 2, completions.requests.count
    assert completions.requests.all? { |request| request[:model] == "gpt-5.3-codex" }
    assert export.risk_assessment_resolutions.all? { |resolution| resolution.file.attached? }
    assert_equal "resource \"example\" \"secure\" {}", export.risk_assessment_resolutions.first.file.download
  end
end
