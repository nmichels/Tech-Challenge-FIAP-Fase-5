class RiskAssessmentResolution < ApplicationRecord
  belongs_to :analysis_export

  has_one_attached :file

  validates :risk_type, :impact_category, :explanation, :resolution, presence: true
  validates :finding_index, presence: true, uniqueness: { scope: :analysis_export_id }
end
