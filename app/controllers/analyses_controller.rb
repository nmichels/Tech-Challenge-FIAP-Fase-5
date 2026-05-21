class AnalysesController < ApplicationController

  def show
    @analysis = Analysis.find(params[:id])
    respond_to do |format|
      format.html
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

  def show
    @analysis = Analysis.find(params[:id])
  end

  private

  def analysis_params
    params.require(:analysis).permit(:file)
  end

  def detect_kind(file)
    content_type = file.content_type

    if content_type.start_with?("text/")
      "text"
    elsif content_type.start_with?("image/")
      "image"
    else
      "unknown"
    end
  end
end
