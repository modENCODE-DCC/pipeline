class AddWrapperClassToProjectTypes < ActiveRecord::Migration
  def self.up
    add_column :project_types, :wrapper_class, :string, { :default => "Command" }
  end

  def self.down
    remove_column :project_types, :wrapper_class
  end
end
