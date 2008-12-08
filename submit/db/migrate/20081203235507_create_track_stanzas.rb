class CreateTrackStanzas < ActiveRecord::Migration
  def self.up
    create_table :track_stanzas do |t|
      t.column :user_id,          :integer, :null => false
      t.column :project_id,       :integer, :null => false
      t.column :marshaled_stanza, :binary, :null => false
    end
  end

  def self.down
    drop_table :track_stanzas
  end
end
