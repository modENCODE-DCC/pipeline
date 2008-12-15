class ChangeTrackTagBodyToText < ActiveRecord::Migration
  def self.up
    change_column :track_tags, :value, :text
  end

  def self.down
    change_column :track_tags, :value, :string
  end
end
