require 'cgi'
class PreviewBrowserController < CommandController
  def initialize(options)
    super
    if block_given? then
      # Don't create a PreviewBrowser object if a subclass gave us a block to use
      yield
      return if self.command_object
    end
    return unless options[:command].nil? # Set in CommandController if :command is given

    self.command_object = PreviewBrowser.new(options)
    preview_params = command_object.project.project_type.preview_params || ''

    previewer = command_object.project.project_type.preview_browser
    command_object.command = "#{URI.escape(previewer + " " + preview_params)} #{URI.escape(options[:current_status])}"

    command_object.timeout = 3600*10 # 10 hours by default
  end

  def run
    super do
      if block_given? then
        # Don't run this method, just pass it along to the super-super class
        return yield
      end

      command_object.status = PreviewBrowser::Status::GENERATING_PREVIEW
      command_object.stdout = ""
      command_object.stderr = ""
      command_object.save

      run_command = command_object.command.split(/ /).map { |i| URI.unescape(i) }[0]

      run_command += " #{command_object.project_id}"

      last_update = Time.now
      (exitvalue, errormessage) = Open5.popen5(run_command) { |stdin, stdout, stderr, exitvaluechannel, sidechannel|
        while result = IO.select([stdout, stderr], nil, nil) do
          break if result[0].empty? # End if we got EOF

          # Read a character
          out_chr = err_chr = nil
          result[0].each { |io|
            case io.object_id
            when stdout.object_id
              out_chr = io.read_nonblock(1) unless io.eof
            when stderr.object_id
              err_chr = io.read_nonblock(1) unless io.eof
            end
          }

          if (out_chr.nil? && err_chr.nil?) then
            # Break the loop if we're at EOF for both stderr and stdout
            break
          end

          command_object.stdout = command_object.stdout + out_chr unless out_chr.nil?
          command_object.stderr = command_object.stderr + err_chr unless err_chr.nil?

          # Save the Report object if it's been 2 seconds and the last chr read
          # from one of the pipes was a newline - application-side flushing, basically
          if (Time.now - last_update) > 2 then
            if (!out_chr.nil? && (out_chr == "\n" || out_chr == "\r")) ||
              (!err_chr.nil? && (err_chr == "\n" || err_chr == "\r")) then
              command_object.save
              command_object.reload
              if command_object.status == Command::Status::CANCELING then
                # TODO: Oh no, interrupt!!!
              end
              last_update = Time.now
            end
          end
        end

        command_object.save
        exitvalue = exitvaluechannel[0].read.to_i
        errormessage = sidechannel[0].read
        [ exitvalue, errormessage ]
      }

      command_object.stderr = command_object.stderr + "\n#{exitvalue}:#{errormessage}"
      command_object.save
      if (exitvalue != 0) then
        #command_object.stderr = "#{exitvalue}:#{errormessage}"
        command_object.status = PreviewBrowser::Status::PREVIEW_FAILED
        command_object.save
      end

      # Reporter exited, tack on newlines if they aren't already there
      command_object.stdout = command_object.stdout + "\n" unless command_object.stdout =~ /\n$/
      command_object.stderr = command_object.stderr + "\n" unless command_object.stderr =~ /\n$/
      command_object.status = PreviewBrowser::Status::PREVIEW_GENERATED unless command_object.status == PreviewBrowser::Status::PREVIEW_FAILED

      # Save one last time
      command_object.save
    end

    return self.do_after
  end

  def do_after(options = {})
    (run_command, old_status) = command_object.command.split(/ /).map { |i| URI.unescape(i) }
    # Set the project's status back to whatever it was no matter the outcome of this command
    p = command_object.project; p.status = old_status; p.save
    if self.status == Report::Status::REPORTING_FAILED then
      return false
    else
      return true
    end
  end

end