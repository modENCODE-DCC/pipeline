class AddClassNameToCommand < ActiveRecord::Migration
  def self.up
    add_column :commands, :class_name, :string
    remove_column :commands, :project_type_id
  end

  def self.down
    remove_column :commands, :class_name
    add_column :commands, :project_type_id, :integer
  end
end
