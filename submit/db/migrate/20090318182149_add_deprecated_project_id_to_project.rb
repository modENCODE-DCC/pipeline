class AddDeprecatedProjectIdToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :deprecated_project_id, :integer
  end

  def self.down
    remove_column :projects, :deprecated_project_id
  end
end
