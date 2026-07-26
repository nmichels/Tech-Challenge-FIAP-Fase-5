class CreateRiskAssessmentResolutions < ActiveRecord::Migration[8.1]
  def change
    create_table :risk_assessment_resolutions do |t|
      t.references :analysis_export, null: false, foreign_key: true
      t.string :risk_type, null: false
      t.string :impact_category, null: false
      t.text :explanation, null: false
      t.text :resolution, null: false

      t.timestamps
    end
  end
end
