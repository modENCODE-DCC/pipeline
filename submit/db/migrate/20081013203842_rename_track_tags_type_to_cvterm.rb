class RenameTrackTagsTypeToCvterm < ActiveRecord::Migration
  def self.up
    rename_column :track_tags, :type, :cvterm
  end

  def self.down
    rename_column :track_tags, :cvterm, :type
  end
end
