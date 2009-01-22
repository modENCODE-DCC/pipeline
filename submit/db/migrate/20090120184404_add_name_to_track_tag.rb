class AddNameToTrackTag < ActiveRecord::Migration
  def self.up
    add_column :track_tags, :name, :string
  end

  def self.down
    remove_column :track_tags, :name
  end
end
