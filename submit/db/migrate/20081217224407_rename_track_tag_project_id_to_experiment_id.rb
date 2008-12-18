class RenameTrackTagProjectIdToExperimentId < ActiveRecord::Migration
  def self.up
    rename_column :track_tags, :project_id, :experiment_id
    add_column :track_tags, :project_id, :integer
  end

  def self.down
    remove_column :track_tags, :project_id
    rename_column :track_tags, :experiment_id, :project_id
  end
end
