require "test_helper"

class RiskAssessmentResolutionsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @analysis = Analysis.create!(kind: "text", status: "completed", result: "done")
    @export = @analysis.create_analysis_export!(format: "json")
    @export.file.attach(
      io: StringIO.new("{}"),
      filename: "analysis.json",
      content_type: "application/json"
    )
  end

  test "enqueues resolution generation for the analysis export" do
    assert_enqueued_with(job: RiskAssessmentResolutionJob, args: [ @export.id ]) do
      post analysis_risk_assessment_resolutions_path(@analysis)
    end

    assert_redirected_to analysis_path(@analysis)
  end

  test "downloads a generated code artifact" do
    resolution = @export.risk_assessment_resolutions.create!(
      risk_type: "spoofing",
      impact_category: "Critical",
      explanation: "Public role",
      resolution: "Restrict IAM",
      finding_index: 0
    )
    resolution.file.attach(
      io: StringIO.new("secure configuration"),
      filename: "correcao.tf",
      content_type: "text/plain"
    )

    get analysis_risk_assessment_resolution_path(@analysis, resolution)

    assert_response :success
    assert_equal "secure configuration", response.body
    assert_match(/attachment/, response.headers["Content-Disposition"])
  end
end
