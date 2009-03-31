class AddCommandIdToEmailMessage < ActiveRecord::Migration
  def self.up
    add_column :email_messages, :command_id, :integer
  end

  def self.down
    remove_column :email_messages, :command_id
  end
end
