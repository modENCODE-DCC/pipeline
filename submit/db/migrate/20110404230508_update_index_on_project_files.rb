class UpdateIndexOnProjectFiles < ActiveRecord::Migration
  def self.up
    execute "DROP INDEX idx_project_files_lower_name"
    execute "CREATE INDEX idx_project_files_sdrf_idx ON project_files(position('sdrf' in lower(file_name)))"
    execute "CREATE INDEX idx_project_files_idf_idx ON project_files(position('idf' in lower(file_name)))"
  end

  def self.down
    execute "CREATE INDEX idx_project_files_lower_name ON project_files(LOWER(file_name))"
    execute "DROP INDEX idx_project_files_sdrf_idx"
    execute "DROP INDEX idx_project_files_idf_idx"
  end
end
