class AddCommandProjectIdIndex < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX idx_command_project_id ON commands(project_id)"
    execute "CREATE INDEX idx_command_project_id_status ON commands(project_id, status)"
  end

  def self.down
    execute "DROP INDEX idx_command_project_id"
    execute "DROP INDEX idx_command_project_id_status"
  end
end
