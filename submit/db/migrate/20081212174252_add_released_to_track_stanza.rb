class AddReleasedToTrackStanza < ActiveRecord::Migration
  def self.up
    add_column :track_stanzas, :released, :boolean, :default => false
  end

  def self.down
    remove_column :track_stanzas, :released
  end
end
