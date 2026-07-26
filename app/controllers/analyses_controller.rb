class AnalysesController < ApplicationController
  def show
    @analysis = Analysis.find(params[:id])

    respond_to do |format|
      format.html do
        export = @analysis.analysis_export
        @json_content = export.file.download.force_encoding("UTF-8") if export&.file&.attached?
        @risk_assessment_resolutions = export&.risk_assessment_resolutions&.with_attached_file || []
      end
      format.md { render markdown: @analysis }
    end
  end

  def new
    @analysis = Analysis.new
  end

  def create
    uploaded_file = analysis_params[:file]

    unless uploaded_file
      redirect_to root_path, alert: "Arquivo inválido"
      return
    end

    kind = detect_kind(uploaded_file)

    @analysis = Analysis.new(kind: kind, status: "pending")
    @analysis.file.attach(uploaded_file)

    if @analysis.save
      AnalyzeFileJob.perform_later(@analysis.id)
      redirect_to analysis_path(@analysis)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def analysis_params
    params.require(:analysis).permit(:file)
  end

  def detect_kind(file)
    content_type = file.content_type

    if content_type.start_with?("image/")
      "image"
    else
      "unknown"
    end
  end
end
