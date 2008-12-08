class CreateTrackTags < ActiveRecord::Migration
  def self.up
    create_table(:track_tags) do |t|
      t.column :project_id,     :integer, :null => false
      t.column :track,          :integer, :null => false
      t.column :value,          :string
      t.column :type,           :string
      t.column :history_depth,  :integer, :default => 0, :null => false
    end
  end

  def self.down
    drop_table :track_tags
  end
end
