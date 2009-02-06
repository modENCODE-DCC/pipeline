class FindTracks < Command
  module Status
    FINDING = "finding tracks"
    FOUND = "tracks found"
    FINDING_FAILED = "finding tracks failed"
  end

  def formatted_status
    if self.stderr.length > 0 then
      "<pre>#{self.stderr}</pre>"
    else
      "<pre>#{self.stdout}</pre>"
    end
  end
  def short_formatted_status
    if self.stderr.length > 0 then
      stderr_lines = Array.new
      self.stderr.split($/).reverse[0...8].each do |line|
        stderr_lines.unshift line[0...50] + (line.size > 50 ? "..." : "")
      end
      return "<pre>#{stderr_lines.join("\n")}</pre>"
    else
      stdout_lines = Array.new
      self.stdout.split($/).reverse[0...8].each do |line|
        stdout_lines.unshift line[0...50] + (line.size > 50 ? "..." : "")
      end
      return "<pre>#{stdout_lines.join("\n")}</pre>"
    end
  end
  def controller
    @controller = FindTracksController.new(:command => self) unless @controller
    @controller
  end
end

