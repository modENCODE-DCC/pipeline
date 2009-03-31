class EmailMessage < ActiveRecord::Base

  belongs_to :to_user, :class_name => User.name, :foreign_key => :to_user_id
  belongs_to :command

  validates_presence_of :to_user_id, :to_type, :command_id
end
