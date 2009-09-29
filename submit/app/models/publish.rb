class Publish < Command
  module Status
    PUBLISHING = "publishing"
    PUBLISHED = "published"
  end

  def initialize(options = {})
    super
    self.status = Publish::Status::PUBLISHED
  end

  def short_formatted_status
    str = "#{prefix} #{self.start_time.strftime("%a, %b %d, %Y (%H:%M)")}"
    str += " by #{user.name}" unless user.nil?
    str
  end
  def formatted_status
    str = "#{prefix} #{self.start_time.strftime("%a, %b %d, %Y (%H:%M)")}"
    str += " by #{user.name}" unless user.nil?
    str
  end
  def prefix
    "Published at"
  end
  def status=(newstatus)
    # Don't update project's status
    write_attribute :status, newstatus
  end
end
