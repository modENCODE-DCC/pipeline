class CreateSemaphores < ActiveRecord::Migration
  def self.up
    create_table "semaphores", :force => true do |t|
      t.column :flag,         :string
      t.column :value,        :string
      t.column :lock_version, :integer, :default => 0
    end
  end

  def self.down
    drop_table "semaphores"
  end
end
