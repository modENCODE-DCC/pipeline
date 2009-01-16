class AddStartTimeAndEndTimeToCommand < ActiveRecord::Migration
  def self.up
    add_column :commands, :start_time, :datetime
    add_column :commands, :end_time, :datetime
  end

  def self.down
    remove_column :commands, :end_time
    remove_column :commands, :start_time
  end
end
