class Load < Command
  module Status
    LOADING = "loading"
    LOADED = "loaded"
    LOAD_FAILED = "load failed"
  end

  #def formatted_status
  #end
  def fail
    self.status = Load::Status::LOAD_FAILED
  end
end
