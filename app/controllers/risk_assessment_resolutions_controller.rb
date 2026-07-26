class RiskAssessmentResolutionsController < ApplicationController
  before_action :set_analysis_export

  def create
    enqueued = @analysis_export.with_lock do
      next false if @analysis_export.resolution_generation_status.in?(%w[queued processing completed])

      @analysis_export.update!(resolution_generation_status: "queued")
      RiskAssessmentResolutionJob.perform_later(@analysis_export.id)
      true
    end

    notice = enqueued ? "Geração de correções iniciada." : "As correções já estão sendo geradas ou foram concluídas."
    redirect_to analysis_path(@analysis_export.analysis), notice: notice
  end

  def show
    resolution = @analysis_export.risk_assessment_resolutions.find(params[:id])
    raise ActiveRecord::RecordNotFound unless resolution.file.attached?

    send_data resolution.file.download,
      filename: resolution.file.filename.to_s,
      type: resolution.file.content_type || "text/plain",
      disposition: "attachment"
  end

  private

  def set_analysis_export
    @analysis_export = AnalysisExport.find_by!(analysis_id: params[:analysis_id], format: "json")
    raise ActiveRecord::RecordNotFound unless @analysis_export.file.attached?
  end
end
