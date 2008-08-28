class Delete < Command
  class Status < Command::Status
    DELETING = "deleting"
    DELETED = "deleted"
    DELETE_FAILED = "delete failed"
  end

  # File uploader (copy source to filename)
  def formatted_status
    project_id = self.command
    project = ""
    begin
      project = Project.find(project_id).name
    rescue
      project = "project with ID #{project_id}"
    end

    case self.status
    when Delete::Status::DELETED
      "Finished deleting #{project}."
    when Delete::Status::DELETE_FAILED
      "Failed to delete #{project}: #{self.stderr}"
    else
      "Currently deleting #{project}."
    end
  end
  def short_formatted_status
    formatted_status
  end
end
