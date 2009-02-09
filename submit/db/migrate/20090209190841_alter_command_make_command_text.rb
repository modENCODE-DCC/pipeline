class AlterCommandMakeCommandText < ActiveRecord::Migration
  def self.up
    change_column :commands, :command, :text
  end

  def self.down
    change_column :commands, :command, :string
  end
end
