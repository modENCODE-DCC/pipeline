
class AddSignatureToFiles < ActiveRecord::Migration
# Adds a signature field to the ProjectArchive
# and ProjectFile objects. This signature is a
# 32 - character long text field containing the
# md5sum checksum of the first 50,000,000 bytes of the file (or, if it is 
# smaller, all of it).
# Used : to check for duplicate files being uploaded 

  def self.up
    add_column :project_files, :signature, :string, :limit => 32
    add_column :project_archives, :signature, :string, :limit => 32
    add_index :project_files, :signature
    add_index :project_archives, :signature
  end

  def self.down
    remove_index :project_files, :signature
    remove_index :project_archives, :signature
    remove_column :project_files, :signature
    remove_column :project_archives, :signature
  end
end
