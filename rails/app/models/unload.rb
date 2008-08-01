class Unload < Command
  class Status < Command::Status
    UNLOADING = "unloading"
    UNLOADED = "unloaded"
    UNLOAD_FAILED = "unload failed"
  end

  #def formatted_status
  #end
end
