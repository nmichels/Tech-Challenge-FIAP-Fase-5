class AnalysisChannel < ApplicationCable::Channel
  def subscribed
    analysis = Analysis.find_by(id: params[:analysis_id])
    reject unless analysis

    stream_for analysis
  end
end
