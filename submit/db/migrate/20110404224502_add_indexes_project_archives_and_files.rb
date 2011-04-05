class AddIndexesProjectArchivesAndFiles < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX idx_project_files_lower_name ON project_files(LOWER(file_name))"
    execute "CREATE INDEX idx_active_file_on_project ON project_archives(is_active, project_id)"
  end

  def self.down
    execute "DROP INDEX idx_project_files_lower_name"
    execute "DROP INDEX idx_active_file_on_project"
  end
end
