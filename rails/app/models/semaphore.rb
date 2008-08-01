class Semaphore < ActiveRecord::Base
  validates_uniqueness_of :flag
end
