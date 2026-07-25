class CreateAnalysisExports < ActiveRecord::Migration[8.1]
  def change
    create_table :analysis_exports do |t|
      t.references :analysis, null: false, foreign_key: true, index: { unique: true }
      t.string :format, null: false

      t.timestamps
    end
  end
end
