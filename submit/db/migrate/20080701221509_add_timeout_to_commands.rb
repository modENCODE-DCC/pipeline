class AddTimeoutToCommands < ActiveRecord::Migration
  def self.up
    add_column :commands, :timeout, :integer
  end

  def self.down
    remove_column :commands, :timeout
  end
end
