class AddCommentToProjectArchive < ActiveRecord::Migration
  def self.up
    add_column :project_archives, :comment, :string
  end

  def self.down
    remove_column :project_archives, :comment
  end
end
