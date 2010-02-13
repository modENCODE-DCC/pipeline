class AddSupersededProjectIdToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :superseded_project_id, :integer
  end

  def self.down
    remove_column :projects, :superseded_project_id
  end
end
