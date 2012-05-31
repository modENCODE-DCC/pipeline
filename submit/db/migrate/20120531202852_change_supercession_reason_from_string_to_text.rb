class ChangeSupercessionReasonFromStringToText < ActiveRecord::Migration
  def self.up
    change_column :projects, :deprecation_reason, :text 
    change_column :projects, :supercession_reason, :text 
  end

  def self.down
    change_column :projects, :deprecation_reason, :string 
    change_column :projects, :supercession_reason, :string 
  end
end
