class AddUniqueIndexToTweetsUuid < ActiveRecord::Migration[8.1]
  def up
    remove_index :tweets, :uuid
    add_index :tweets, :uuid, unique: true
  end

  def down
    remove_index :tweets, :uuid
    add_index :tweets, :uuid
  end
end
