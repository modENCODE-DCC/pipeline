class AddCommandStatusIndex < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX idx_command_status ON commands(status)"
  end

  def self.down
    execute "DROP INDEX idx_command_status"
  end
end
