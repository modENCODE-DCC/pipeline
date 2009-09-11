class ChangeTrackStanzaMarshaledStanzaToText < ActiveRecord::Migration
  def self.up
    change_column(:track_stanzas, :marshaled_stanza, :text, :null => false)
  end

  def self.down
    change_column(:track_stanzas, :marshaled_stanza, :binary, :null => false)
  end
end
