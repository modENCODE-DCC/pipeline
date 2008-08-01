class Load < Command
  class Status < Command::Status
    LOADING = "loading"
    LOADED = "loaded"
    LOAD_FAILED = "load failed"
  end

  #def formatted_status
  #end
end
