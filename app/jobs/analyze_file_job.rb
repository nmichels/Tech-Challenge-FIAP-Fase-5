class AnalyzeFileJob < ApplicationJob
  queue_as :default

  def perform(analysis_id)
    analysis = Analysis.find(analysis_id)

    analysis.update!(status: "processing")

    result = if analysis.kind == "text"
      analyze_text(analysis)
    elsif analysis.kind == "image"
      analyze_image(analysis)
    else
      "Unsupported file type"
    end

    analysis.update!(
      status: "completed",
      result: result
    )

    ExportAnalysisResultJob.perform_later(analysis.id)
  rescue => e
    analysis.update!(
      status: "failed",
      result: e.message
    ) if analysis

    raise e
  end

  private

  def client
    @client ||= OpenAI::Client.new(
      api_key: ENV.fetch("OPENAI_API_KEY")
    )
  end

  def analyze_text(analysis)
    file_path = download_file(analysis)
    base_64_content = Base64.strict_encode64(File.binread(file_path))

    prompt = <<~PROMPT
      Evaluate the attached markdown file and:
      1. Perform a risk assessment based on STRIDE methodology
      2. Suggest additional components and features based on identified cloud providers
      ### CRITICAL
      Render final result in Portuguese from Brazil
    PROMPT

    response = client.chat.completions.create(
        model: "gpt-5.6-sol",
        messages: [
          {
            role: "system",
            content: "You are a senior software architect specialized in software security. #{prompt}"
          },
          {
            role: "user",
            content: [
              type: "input_file",
              input_file: {
                data: base_64_content
              }
            ]
          }
        ],
        modalities: [ "text" ]
    )

    response.choices.first.message.content
  ensure
    File.delete(file_path) if file_path && File.exist?(file_path)
  end

  def analyze_image(analysis)
    file_path = download_file(analysis)

    base64_image = Base64.strict_encode64(File.read(file_path))

    response = client.chat.completions.create(
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
                ### CRITICAL
                Render final result in Portuguese
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

    response.choices.first.message.content
  ensure
    File.delete(file_path) if file_path && File.exist?(file_path)
  end

  private

  def download_file(analysis)
    extension = analysis.file.filename.extension
    path = Rails.root.join("tmp", "#{SecureRandom.uuid}.#{extension}")

    File.open(path, "wb") do |f|
      f.write(analysis.file.download)
    end

    path.to_s
  end
end
