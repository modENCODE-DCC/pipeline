require 'find'
require 'escape'
class ReportGeoController < ReportController
  def initialize(options)
    super do
      return unless options[:command].nil? # Set in CommandController if :command is given

      self.command_object = ReportGeo.new(options)
      project_reporter_params = command_object.project.project_type.reporter_params || ''
      package_dir = File.join(ExpandController.path_to_project_dir(command_object.project), "geo")

      reporter = command_object.project.project_type.reporter
      command_object.command = "#{URI.escape(reporter)} #{URI.escape(project_reporter_params)} #{URI.escape(package_dir)}"

      command_object.timeout = 3600*10 # 10 hours by default
    end
  end

  def run
    super do

      return yield if block_given?

      puts "nope"
      command_object.status = Report::Status::REPORTING
      command_object.stdout = ""
      command_object.stderr = ""
      command_object.save

      (reporter, params, package_dir, make_tarball, send_to_geo) = command_object.command.split(/ /).map { |i| URI.unescape(i) }
      Dir.mkdir(package_dir,0775) unless File.exists?(package_dir)
      if !File.directory? package_dir then
        command_object.stderr = command_object.stderr + "Can't find geo package directory #{package_dir}"
        command_object.status = Report::Status::REPORTING_FAILED
        command_object.save
        self.do_after
        return false
      end

      # Clean up existing files
      Find.find(package_dir) do |path|
        Find.prune if File.directory?(path) && path != package_dir # Don't recurse
        if File.basename(path) =~ /^\d+[_\.]/ then
          File.unlink(path)
        end
      end

      run_command = "#{reporter} -unique_id #{command_object.project.id} -out \"#{package_dir}\" #{params}"
      if send_to_geo then
        run_command += " -use_existent_tarball 1 -send_to_geo 1"
      elsif make_tarball then
        run_command += " -use_existent_metafile 1 -make_tarball 1"
      end

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

      # Errors?
      if (!exitvalue.nil? && exitvalue != 0) then
        command_object.stderr = command_object.stderr + "\nError message: #{exitvalue}:#{errormessage}"
        command_object.status = Report::Status::REPORTING_FAILED
        command_object.save
      end

      # Reporter exited, tack on newlines if they aren't already there
      command_object.stdout = command_object.stdout + "\n" unless command_object.stdout =~ /\n$/
      command_object.stderr = command_object.stderr + "\n" unless command_object.stderr =~ /\n$/
      if make_tarball && send_to_geo then
        command_object.status = Report::Status::REPORTED unless command_object.status == Report::Status::REPORTING_FAILED
      elsif make_tarball then
        command_object.status = Report::Status::REPORT_TARBALL_GENERATED unless command_object.status == Report::Status::REPORTING_FAILED
      else
        command_object.status = Report::Status::REPORT_GENERATED unless command_object.status == Report::Status::REPORTING_FAILED
      end

      # Save one last time
      command_object.save
      return self.do_after
    end
  end
end
