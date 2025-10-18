class CreateResourceContents < ActiveRecord::Migration[7.0]
  def change
    create_table :resource_contents do |t|
      t.references :resource, null: false, foreign_key: true, index: { unique: true }
      t.text :content

      t.timestamps
    end
  end
end 