class AnalyzeFileJob < ApplicationJob
  queue_as :default

  def perform(analysis_id)
    analysis = Analysis.find(analysis_id)

    analysis.update!(status: "processing")
    broadcast(analysis, event: "analysis_started", status: analysis.translate_status)

    result = if analysis.kind == "image"
      analyze_image(analysis)
    else
      "Unsupported file type"
    end

    analysis.update!(
      status: "completed",
      result: result
    )
    broadcast(analysis, event: "analysis_completed", status: analysis.translate_status)

    ExportAnalysisResultJob.perform_later(analysis.id)
  rescue => e
    if analysis
      analysis.update!(
        status: "failed",
        result: e.message
      )
      broadcast(analysis, event: "analysis_failed", status: analysis.translate_status, error: e.message)
    end

    raise e
  end

  private

  def client
    @client ||= OpenAI::Client.new(
      api_key: ENV.fetch("OPENAI_API_KEY")
    )
  end

  def analyze_image(analysis)
    file_path = download_file(analysis)

    base64_image = Base64.strict_encode64(File.read(file_path))

    stream_completion(analysis,
      model: "gpt-5.6-sol",
      messages: [
        {
          role: "system",
          content: "You are a senior software architect specialized in software security."
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: <<~TEXT
                Evaluate the attached image file and:
                1. Perform a risk assessment based on STRIDE methodology
                2. Suggest additional components and features based on identified cloud providers
                3. Structure breakdown of the analysis:
                  3.1 - Architecture overview - high level summary of architecture/components and critical points
                  3.2 - STRIDE Assessment
                    3.2.1 - Spoofing focused analysis, threats, impact and recommendations
                    3.2.2 - Tampering focused analysis, threats, impact and recommendations
                    3.2.3 - Repudiation focused analysis, threats, impact and recommendations
                    3.2.4 - Information Disclosure focused analysis, threats, impact and recommendations
                    3.2.5 - Denial of Service  focused analysis, threats, impact and recommendations
                    3.2.6 - Elevation of Privilege focused analysis, threats, impact and recommendations
                4. Final Assessment Summary
                ### CRITICAL
                Always classify impact with Low, Medium, High or Critical categories
                Render final result in Portuguese from Brazil
                **Do not translate technical terms, architecture component names or cloud resourcers terms**
                TEXT
              },
              {
                type: "image_url",
                image_url: {
                  url: "data:image/png;base64,#{base64_image}"
                }
              }
            ]
        }
      ]
    )
  ensure
    File.delete(file_path) if file_path && File.exist?(file_path)
  end

  def stream_completion(analysis, **params)
    result = +""

    client.chat.completions.stream(**params).text.each do |delta|
      result << delta
      analysis.update_column(:result, result)
      broadcast(analysis, event: "analysis_delta", delta: delta, content: result)
    end

    result
  end

  def broadcast(analysis, payload)
    AnalysisChannel.broadcast_to(analysis, payload)
  end

  def download_file(analysis)
    extension = analysis.file.filename.extension
    path = Rails.root.join("tmp", "#{SecureRandom.uuid}.#{extension}")

    File.open(path, "wb") do |f|
      f.write(analysis.file.download)
    end

    path.to_s
  end
end
