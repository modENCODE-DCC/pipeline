class AddPiToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :pi, :string
    Project.all.each { |p|
      p.lab = p.user.pi unless p.user.nil?
      p.save
    }
  end

  def self.down
    remove_column :projects, :pi
  end
end
