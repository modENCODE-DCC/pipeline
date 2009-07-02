class AddLabToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :lab, :string
    Project.all.each { |p|
      p.lab = p.user.pi unless p.user.nil?
      p.save
    }
  end

  def self.down
    remove_column :projects, :lab
  end
end
