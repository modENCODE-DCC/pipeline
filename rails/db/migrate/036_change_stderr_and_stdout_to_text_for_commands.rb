class ChangeStderrAndStdoutToTextForCommands < ActiveRecord::Migration
  def self.up
    change_column :commands, :stderr, :text
    change_column :commands, :stdout, :text
  end

  def self.down
    change_column :commands, :stderr, :string
    change_column :commands, :stdout, :string
  end
end
