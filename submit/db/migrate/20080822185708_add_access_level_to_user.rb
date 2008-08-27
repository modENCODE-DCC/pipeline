class AddAccessLevelToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :accesslevel, :string, :default => 'User'
  end

  def self.down
    remove_column :users, :accesslevel
  end
end
