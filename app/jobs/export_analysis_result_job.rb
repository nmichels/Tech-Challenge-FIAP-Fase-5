class ExportAnalysisResultJob < ApplicationJob
  queue_as :default

  def perform(analysis_id)
    analysis = Analysis.completed.find(analysis_id)
    json = generate_json(analysis.result)
    export = analysis.analysis_export || analysis.build_analysis_export(format: "json")

    export.format = "json"
    export.file.attach(
      io: StringIO.new(json),
      filename: "analysis-#{analysis.id}.json",
      content_type: "application/json"
    )
    export.save!
  end

  private

  def client
    @client ||= OpenAI::Client.new(
      api_key: ENV.fetch("OPENAI_API_KEY")
    )
  end

  def generate_json(result)
    response = client.chat.completions.create(
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

    response.choices.first.message.content
  end
end
