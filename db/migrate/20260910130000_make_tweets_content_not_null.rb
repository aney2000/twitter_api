class MakeTweetsContentNotNull < ActiveRecord::Migration[8.1]
  def up
    change_column_null :tweets, :content, false
  end

  def down
    change_column_null :tweets, :content, true
  end
end
