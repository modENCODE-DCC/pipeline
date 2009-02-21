class AddUniqueConstraintToTrackTags < ActiveRecord::Migration
  def self.up
    add_index :track_tags, [ :experiment_id, :track, :value, :cvterm, :history_depth, :project_id, :name ], :unique => true
  end

  def self.down
    remove_index :track_tags, [ :experiment_id, :track, :value, :cvterm, :history_depth, :project_id, :name ]
  end
end
