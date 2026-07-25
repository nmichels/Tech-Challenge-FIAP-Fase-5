class AnalysisExportsController < ApplicationController
  def show
    export = AnalysisExport.find_by!(analysis_id: params[:analysis_id], format: "json")

    raise ActiveRecord::RecordNotFound unless export.file.attached?

    send_data export.file.download,
      filename: export.file.filename.to_s,
      type: export.file.content_type || "application/json",
      disposition: "inline"
  end
end
