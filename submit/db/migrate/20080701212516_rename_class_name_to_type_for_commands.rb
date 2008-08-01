class RenameClassNameToTypeForCommands < ActiveRecord::Migration
  def self.up
    rename_column :commands, :class_name, :type
  end

  def self.down
    rename_column :commands, :type, :class_name
  end
end
