class Report < Command
  module Status
    REPORTING = "generating report"
    REPORTED = "reported to GEO"
    REPORT_TARBALL_GENERATED = "report tarball generated"
    REPORT_GENERATED = "report generated"
    REPORTING_FAILED = "report generation failed"
  end

  #def formatted_status
  #end
  #
  def fail
    self.status = Report::Status::REPORTING_FAILED
  end
end


