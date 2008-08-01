class AddIsOverwrittenFlagToProjectFile < ActiveRecord::Migration
  def self.up
    add_column :project_files, :is_overwritten, :boolean, { :default => false }
  end

  def self.down
    remove_column :project_files, :is_overwritten
  end
end
