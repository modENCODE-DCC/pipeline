class AddCvtermIndexToTrackTags < ActiveRecord::Migration
  def self.up
    add_index :track_tags, :cvterm
  end

  def self.down
    remove_index :track_tags, :cvterm
  end
end
