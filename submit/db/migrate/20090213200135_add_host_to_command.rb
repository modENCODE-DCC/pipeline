class AddHostToCommand < ActiveRecord::Migration
  def self.up
    add_column :commands, :host, :string
  end

  def self.down
    remove_column :commands, :host
  end
end
