class AddIndexesToTrackTags < ActiveRecord::Migration
  def self.up
    add_index :track_tags, [ :project_id, :name ]
    add_index :track_tags, [ :project_id, :name, :cvterm ]
  end

  def self.down
    remove_index :track_tags, [ :project_id, :name ]
    remove_index :track_tags, [ :project_id, :name, :cvterm ]
  end
end
