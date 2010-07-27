class Release < Command
  module Status
    AWAITING_RELEASE = "awaiting release"
    RELEASE_REJECTED = "release not approved"
    USER_RELEASED = "approved by user, awaiting DCC approval"
    DCC_RELEASED = "approved by DCC, awaiting user approval"
    RELEASED = "released"
  end

  def initialize(options = {})
    super
    self.status = Release::Status::AWAITING_RELEASE if self.queued?
  end

  def short_formatted_status
    if self.status == Release::Status::RELEASE_REJECTED then
      "#{self.stdout}\n#{self.stderr}"
    else
      "#{self.stdout}"
    end
  end
  def formatted_status
    if self.status == Release::Status::RELEASE_REJECTED then
      "#{self.stdout}<blockquote>#{self.stderr}</blockquote>"
    else
      "#{self.stdout}"
    end
  end
  def fail
    self.status = Release::Status::RELEASE_REJECTED
  end

  def backdated_by_project
    if self.stderr =~ /Backdated to submission #\d+\.$/ then
      old_id = self.stderr.match(/Backdated to submission #(\d+)\.$/)[1]
      return Project.find(old_id)
    end
    return nil
  end
  
end
