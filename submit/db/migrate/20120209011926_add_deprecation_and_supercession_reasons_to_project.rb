class AddDeprecationAndSupercessionReasonsToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :deprecation_reason, :string
    add_column :projects, :supercession_reason, :string
  end

  def self.down
    remove_column :projects, :supercession_reason, :string
    remove_column :projects, :deprecation_reason, :string
  end
end
