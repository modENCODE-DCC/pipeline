class RenameUserPiToUserLab < ActiveRecord::Migration
  def self.up
    rename_column :users, :pi, :lab
  end

  def self.down
    rename_column :users, :lab, :pi
  end
end
