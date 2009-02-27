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
    "#{prefix} #{self.started_at.strftime("%a, %b %d, %Y (%H:%M)")}"
  end
  def formatted_status
    "#{prefix} #{self.started_at.strftime("%a, %b %d, %Y (%H:%M)")}"
  end
  def prefix
    "Published at"
  end
  def status=(newstatus)
    # Don't update project's status
    write_attribute :status, newstatus
  end
end
