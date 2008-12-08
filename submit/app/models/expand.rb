class Expand < Command
  module Status
    EXPANDING = "expanding"
    EXPANDED = "expanded"
    EXPAND_FAILED = "expand failed"
  end

  def formatted_status
    case self.status
    when Expand::Status::EXPANDING
      "Expanding..."
    when Expand::Status::EXPAND_FAILED
      "Expanding failed!<br/>\n#{self.stderr}"
    else
      "Expanded:<br/>\n<pre>#{self.stdout}</pre>"
    end
  end

  def status=(newstatus)
    write_attribute :status, newstatus

    if newstatus == Expand::Status::EXPANDED then
      # Make sure all expansions are done before updating project
      expand_commands = self.project.commands.find_all_by_type(self.class.name)
      expand_commands.reject! { |c| c == self }
      unless (expand_commands.find_all { |e| e.status == Expand::Status::EXPANDING || e.status == Command::Status::QUEUED }.size > 0) then
        # Do not complete expansion unless all Expand objects have been expanded
        self.project.status = Expand::Status::EXPANDED
        self.project.save
      end
    else 
      self.project.status = newstatus
      self.project.save
    end
  end

end

