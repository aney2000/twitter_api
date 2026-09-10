class CreateTweets < ActiveRecord::Migration[8.1]
  def change
    create_table :tweets do |t|
      t.text :content
      t.string :uuid

      t.timestamps
    end
    add_index :tweets, :uuid
  end
end
