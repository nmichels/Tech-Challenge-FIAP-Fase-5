class AnalysisExport < ApplicationRecord
  belongs_to :analysis

  has_one_attached :file

  validates :format, presence: true, inclusion: { in: %w[json] }
end
