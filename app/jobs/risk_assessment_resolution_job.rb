class RiskAssessmentResolutionJob < ApplicationJob
  queue_as :default

  TARGET_IMPACT_CATEGORIES = %w[high critical].freeze

  def perform(analysis_export_id)
    export = AnalysisExport.find(analysis_export_id)
    analysis = export.analysis
    export.update!(resolution_generation_status: "processing")
    broadcast(analysis, event: "resolutions_started")

    findings = qualifying_findings(JSON.parse(export.file.download))
    resolutions = findings.each_with_index.map do |finding, finding_index|
      existing = export.risk_assessment_resolutions.find_by(finding_index: finding_index)
      existing || generate_resolution(export, finding.merge(finding_index: finding_index))
    end

    export.update!(resolution_generation_status: "completed")
    broadcast(
      analysis,
      event: "resolutions_completed",
      resolutions: resolutions.map { |resolution| resolution_payload(analysis, resolution) }
    )
  rescue => e
    export&.update_column(:resolution_generation_status, "failed")
    broadcast(analysis, event: "resolutions_failed", error: e.message) if analysis
    raise e
  end

  private

  def client
    @client ||= OpenAI::Client.new(api_key: ENV.fetch("OPENAI_API_KEY"))
  end

  def qualifying_findings(document)
    document.each_with_object([]) do |(risk_type, value), findings|
      next unless value.is_a?(Array)

      value.each do |item|
        next unless item.is_a?(Hash)
        next unless TARGET_IMPACT_CATEGORIES.include?(item["impact_category"].to_s.downcase)

        findings << {
          risk_type: risk_type,
          impact_category: item.fetch("impact_category"),
          explanation: item.fetch("explanation"),
          resolution: item.fetch("resolution", "")
        }
      end
    end
  end

  def generate_resolution(export, finding)
    content = client.chat.completions.create(
      model: "gpt-5.6-sol",
      messages: [
        {
          role: "system",
          content: <<~PROMPT
            You are a senior cloud security engineer. Generate one directly usable code artifact that mitigates the supplied architectural risk.
            Prefer the smallest clear deployment or cloud configuration file possible. Use configurable variables instead of environment-specific values.
            Return only the file contents, without Markdown fences or explanatory prose. Do not invent infrastructure beyond what is needed for the mitigation.
          PROMPT
        },
        {
          role: "user",
          content: <<~CONTEXT
            STRIDE category: #{finding[:risk_type]}
            Risk level: #{finding[:impact_category]}
            Finding: #{finding[:explanation]}
            Recommended mitigation: #{finding[:resolution]}
          CONTEXT
        }
      ]
    ).choices.first.message.content.to_s

    resolution = export.risk_assessment_resolutions.create!(finding)
    resolution.file.attach(
      io: StringIO.new(content),
      filename: artifact_filename(resolution),
      content_type: "text/plain"
    )
    resolution
  end

  def artifact_filename(resolution)
    risk_type = resolution.risk_type.parameterize(separator: "_")
    "correcao_#{resolution.id}_#{risk_type}.txt"
  end

  def resolution_payload(analysis, resolution)
    {
      id: resolution.id,
      label: "#{resolution.risk_type.humanize} — #{resolution.impact_category}",
      url: Rails.application.routes.url_helpers.analysis_risk_assessment_resolution_path(
        analysis,
        resolution
      )
    }
  end

  def broadcast(analysis, payload)
    AnalysisChannel.broadcast_to(analysis, payload)
  end
end
