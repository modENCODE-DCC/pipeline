class Validate < Command
  module Status
    VALIDATING = "validating"
    VALIDATED = "validated"
    VALIDATION_FAILED = "validation failed"
  end

  #def formatted_status
  #end
  #
  def fail
    self.status = Validate::Status::VALIDATION_FAILED
  end
end
