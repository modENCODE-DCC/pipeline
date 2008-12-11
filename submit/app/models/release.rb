class Release < Command
  module Status
    AWAITING_RELEASE = "awaiting release"
    RELEASE_REJECTED = "release failed"
    USER_RELEASED = "approved by user, awaiting DCC approval"
    DCC_RELEASED = "approved by DCC, awaiting user approval"
    RELEASED = "released"
  end

  #def formatted_status
  #end
  #
end
