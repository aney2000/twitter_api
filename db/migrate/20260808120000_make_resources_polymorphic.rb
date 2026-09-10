class MakeResourcesPolymorphic < ActiveRecord::Migration[8.1]
  def up
    add_reference :resources, :resourceable, polymorphic: true, null: true

    execute "UPDATE resources SET resourceable_id = tweet_id, resourceable_type = 'Tweet'"

    change_column_null :resources, :resourceable_id, false
    change_column_null :resources, :resourceable_type, false

    remove_reference :resources, :tweet, foreign_key: true
  end

  def down
    add_reference :resources, :tweet, null: true, foreign_key: true

    execute "DELETE FROM resources WHERE resourceable_type != 'Tweet'"
    execute "UPDATE resources SET tweet_id = resourceable_id"

    change_column_null :resources, :tweet_id, false

    remove_reference :resources, :resourceable, polymorphic: true
  end
end
