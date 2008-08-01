class AddActiveFlagAndRemoveActiveMaskFromArchives < ActiveRecord::Migration
  def self.up
    add_column :project_archives, :is_active, :boolean, { :default => true }
    remove_column :projects, :archives_active
    remove_column :projects, :archive_count
  end

  def self.down
    remove_column :project_archives, :is_active
    add_column :projects, :archives_active, :text
    add_column :projects, :archive_count, :integer
  end
end
