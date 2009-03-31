class CreateEmailMessages < ActiveRecord::Migration
  def self.up
    create_table :email_messages do |t|
      t.integer :to_user_id
      t.text :message

      t.timestamps
    end
  end

  def self.down
    drop_table :email_messages
  end
end
