class ExportAnalysisResultJob < ApplicationJob
  queue_as :default

  def perform(analysis_id)
    analysis = Analysis.completed.find(analysis_id)
    broadcast(analysis, event: "export_started")
    json = generate_json(analysis, analysis.result)
    export = analysis.analysis_export || analysis.build_analysis_export(format: "json")

    export.format = "json"
    export.file.attach(
      io: StringIO.new(json),
      filename: "analysis-#{analysis.id}.json",
      content_type: "application/json"
    )
    export.save!

    broadcast(analysis, event: "export_completed")
  rescue => e
    broadcast(analysis, event: "export_failed", error: e.message) if analysis
    raise e
  end

  private

  def broadcast(analysis, payload)
    Rails.logger.info(
      "[ActionCable] Broadcasting AnalysisChannel event=#{payload[:event]} " \
      "analysis_id=#{analysis.id} delta_length=#{payload[:delta]&.length || 0} " \
      "adapter=#{ActionCable.server.config.cable.fetch("adapter")}"
    )
    AnalysisChannel.broadcast_to(analysis, payload)
  end

  def client
    @client ||= OpenAI::Client.new(
      api_key: ENV.fetch("OPENAI_API_KEY")
    )
  end

  def generate_json(analysis, result)
    json = +""
    stream = client.chat.completions.stream(
      model: "gpt-5.6-sol",
      messages: [
        {
          role: "system",
          content: <<~PROMPT
            Convert the supplied software security analysis to JSON using the required schema.
            Preserve the original Brazilian Portuguese content and do not add risks that are not present in the analysis.
          PROMPT
        },
        {
          role: "user",
          content: result
        }
      ],
      response_format: JsonSchema::RISK_ANALYSIS
    )

    stream.text.each do |delta|
      json << delta
      broadcast(analysis, event: "export_delta", delta: delta)
    end

    json
  end
end
