class TrackTag < ActiveRecord::Base
  belongs_to :project
  validates_presence_of :project_id
  validates_presence_of :experiment_id
end
