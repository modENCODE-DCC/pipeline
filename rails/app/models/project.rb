class Project < ActiveRecord::Base

  belongs_to :user
  belongs_to :project_type
  has_many :project_archives, :dependent => :destroy, :order => :archive_no
  has_many :commands, :dependent => :destroy, :order => :position

  validates_presence_of :name
  validates_presence_of :project_type_id
  validates_presence_of :status
  validates_presence_of :user_id
  validates_uniqueness_of   :name


  class Status
    # Status constants
    NEW = "new"
  end

end
