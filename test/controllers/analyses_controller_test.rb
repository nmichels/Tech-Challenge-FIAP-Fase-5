require "test_helper"

class AnalysesControllerTest < ActionDispatch::IntegrationTest
  test "renders a completed analysis while its JSON export is pending" do
    analysis = Analysis.create!(kind: "text", status: "completed", result: "# Resultado")

    get analysis_path(analysis)

    assert_response :success
    assert_select "#json-preview", text: ""
    assert_select "#json-link[hidden]"
    assert_select "#json-link-pending", text: "Exportação JSON em andamento"
    assert_select "#resolutions-section[hidden]"
  end

  test "shows the generate fixes CTA when the JSON export is ready" do
    analysis = Analysis.create!(kind: "text", status: "completed", result: "# Resultado")
    export = analysis.create_analysis_export!(format: "json")
    export.file.attach(io: StringIO.new("{}"), filename: "analysis.json", content_type: "application/json")

    get analysis_path(analysis)

    assert_response :success
    assert_select "#resolutions-section:not([hidden])"
    assert_select "#generate-resolutions", text: "Gerar correções"
  end

  test "loads the bundled Action Cable client" do
    analysis = Analysis.create!(kind: "text", status: "pending")

    get analysis_path(analysis)

    assert_response :success
    assert_includes response.body, "/assets/actioncable.esm"
    assert_not_includes response.body, "@rails/actioncable@8.1.300"
  end
end
