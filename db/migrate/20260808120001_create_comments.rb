class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :tweet, null: false, foreign_key: true
      t.text :content, null: false
      t.string :uuid, null: false

      t.timestamps
    end

    add_index :comments, :uuid, unique: true
  end
end
