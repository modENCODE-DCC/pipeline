class CreateCommands < ActiveRecord::Migration
  def self.up
    create_table :commands do |t|
      t.integer :project_id
      t.integer :project_type_id
      t.string :command
      t.string :stdout
      t.string :stderr
      t.string :status
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :commands
  end
end
