class ProjectArchive < ActiveRecord::Base

  belongs_to :project
  has_many :project_files, :dependent => :destroy
  acts_as_list :scope => :project_id, :column => "archive_no", :order => "archive_no"

#  validates_presence_of :file_name
#  validates_presence_of :file_size
#  validates_presence_of :file_date
  validates_presence_of :project_id

  module Status
    NOT_EXPANDED = "not expanded"
    EXPANDED = "expanded"
    EXPANDING = "expanding"
    EXPAND_FAILED = "expand failed"
    UPLOADING = "uploading"
  end

  def initialize(options = {})
    super
    if self.status.nil? || self.status.empty? then
      self.status = ProjectArchive::Status::NOT_EXPANDED
    end
  end

  protected
    def validate
      #errors.add(:price, "should be a positive value") if price.nil? || price < 0.01
    end

end
