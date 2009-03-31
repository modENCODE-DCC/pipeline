class CreateUserPreferences < ActiveRecord::Migration
  def self.up
    create_table :user_preferences do |t|
      t.integer :user_id
      t.string :key
      t.string :value
    end
    add_index :user_preferences, [ :user_id, :key ], :unique => true
  end

  def self.down
    remove_index :user_preferences, [ :user_id, :key ]
    drop_table :user_preferences
  end
end
