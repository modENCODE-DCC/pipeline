class UserPreference < ActiveRecord::Base

  belongs_to :user

  validates_uniqueness_of :key, :scope => :user_id
  validates_presence_of :user_id, :key
end
