class AddBrokenFlagAndBrokenReasonToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :is_broken, :boolean, { :default => false }
    add_column :projects, :broken_reason, :text
  end

  def self.down
    remove_column :projects, :is_broken
    remove_column :projects, :broken_reason
  end
end
