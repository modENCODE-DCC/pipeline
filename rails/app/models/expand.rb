class Expand < Command
  class Status < Command::Status
    EXPANDING = "expanding"
    EXPANDED = "expanded"
    EXPAND_FAILED = "expand_failed"
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

end

