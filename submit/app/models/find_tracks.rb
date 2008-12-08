class FindTracks < Command
  module Status
    FINDING = "finding tracks"
    FOUND = "tracks found"
    FINDING_FAILED = "finding tracks failed"
  end

  def formatted_status
    "<pre>#{self.stdout}</pre>"
  end
  def short_formatted_status
    stdout_lines = Array.new
    self.stdout.split($/).reverse[0...8].each do |line|
      stdout_lines.unshift line[0...50] + (line.size > 50 ? "..." : "")
    end
    "<pre>#{stdout_lines.join("\n")}</pre>"
  end
  def controller
    @controller = FindTracksController.new(:command => self) unless @controller
    @controller
  end
end

