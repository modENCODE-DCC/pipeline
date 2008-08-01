class AddLoadAndUnloadWrapperClassToProjectType < ActiveRecord::Migration
  def self.up
    add_column :project_types, :load_wrapper_class, :string
    add_column :project_types, :unload_wrapper_class, :string
    rename_column :project_types, :wrapper_class, :validate_wrapper_class
  end

  def self.down
    remove_column :project_types, :unload_wrapper_class
    remove_column :project_types, :load_wrapper_class
    rename_column :project_types, :validate_wrapper_class, :wrapper_class
  end
end
