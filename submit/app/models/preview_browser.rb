class PreviewBrowser < Command
  module Status
    GENERATING_PREVIEW = "generating preview database"
    PREVIEW_GENERATED = "preview database generated"
    PREVIEW_FAILED = "preview generation failed"
  end

  #def formatted_status
  #end
  #
  def fail
    self.status = Report::Status::PREVIEW_FAILED
  end
end


