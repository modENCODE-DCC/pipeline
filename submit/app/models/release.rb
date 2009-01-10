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
    self.status = Release::Status::AWAITING_RELEASE if self.status == Command::Status::QUEUED
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
  
end
