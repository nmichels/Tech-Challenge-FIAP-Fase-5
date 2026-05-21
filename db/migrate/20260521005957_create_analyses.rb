class CreateAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :analyses do |t|
      t.string :kind
      t.string :status
      t.text :result

      t.timestamps
    end
  end
end
