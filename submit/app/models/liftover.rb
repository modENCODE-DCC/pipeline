class Liftover < Command
  ERR_BEG = "BEG_ERR"
  ERR_END = "END_ERR"
  module Status
    LIFTING = "lifting"
    LIFTED = "lifted over"
    LIFTOVER_FAILED = "liftover failed"
  end

  def formatted_status
    html_stdout = self.stdout.gsub("\n", "<br/>")
    html_stderr = self.stderr.gsub("\n", "<br/>")
    # Mark errors in red
    # Don't repeat the error header for consecutive errors.
    html_stdout.gsub!("#{ERR_END}#{ERR_BEG}", "")
    html_stdout.gsub!(ERR_BEG, "<font color=\"red\">ERROR: ")
    html_stdout.gsub!(ERR_END, "</font>")
    # Mark errors from STDOUT in red
    html_stderr = self.stderr.gsub("\n", "<br/>")
    # Two columns : Output (out & error) and results of lifting
    status = <<-ENDHTML
    <table cellpadding="5px">
      <tr><td width="50%" style="vertical-align:top;border:thin solid black;">
        <b>Liftover Tool Output</b><br/><br/>
        #{html_stdout}
      </td><td style="vertical-align:top;border:thin solid black;">
        <b>Features With Internal Changes</b><br/>
        #{html_stderr}
      </td></tr>
    </table>
    ENDHTML
  end

end
