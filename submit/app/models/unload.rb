class Unload < Command
  module Status
    UNLOADING = "unloading"
    UNLOADED = "unloaded"
    UNLOAD_FAILED = "unload failed"
  end

  #def formatted_status
  #end
  def fail
    self.status = Unload::Status::UNLOAD_FAILED
  end
end
