class AddResolutionGenerationStatusToAnalysisExports < ActiveRecord::Migration[8.1]
  def change
    add_column :analysis_exports, :resolution_generation_status, :string
    add_column :risk_assessment_resolutions, :finding_index, :integer, null: false
    add_index :risk_assessment_resolutions,
      [ :analysis_export_id, :finding_index ],
      unique: true,
      name: "index_resolutions_on_export_and_finding"
  end
end
