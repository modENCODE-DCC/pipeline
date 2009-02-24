class AddThrottleFlagToCommand < ActiveRecord::Migration
  def self.up
    add_column :commands, :throttle, :boolean, {:default => false}
    Command.update_all("throttle = false")
  end

  def self.down
    remove_column :commands, :throttle
  end
end
