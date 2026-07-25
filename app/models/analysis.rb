class Analysis < ApplicationRecord
  has_one :analysis_export, dependent: :destroy
  has_one_attached :file

  validates :kind, presence: true
  validates :status, presence: true

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }

  def to_markdown
    result
  end

  def translate_status
    case status
    when "pending"
      "Aguardando inicialização"
    when "processing"
      "Em processamento"
    when "completed"
      "Concluída com sucesso"
    when "failed"
      "erro"
    end
  end
end
