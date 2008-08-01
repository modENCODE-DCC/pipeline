class AddQueuePositionToCommand < ActiveRecord::Migration
  def self.up
    add_column :commands, :queue_position, :integer
  end

  def self.down
    remove_column :commands, :queue_position
  end
end
