class AddToTypeToEmailMessage < ActiveRecord::Migration
  def self.up
    add_column :email_messages, :to_type, :string
  end

  def self.down
    remove_column :email_messages, :to_type
  end
end
