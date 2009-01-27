require 'escape'
class ValidateIdf2chadoxmlController < ValidateController
  def initialize(options)
    super do
      return unless options[:command].nil? # Set in CommandController if :command is given

      self.command_object = ValidateIdf2chadoxml.new(options)
      project_type_params = command_object.project.project_type.type_params || ''
      package_dir = File.join(ExpandController.path_to_project_dir(command_object.project), "extracted")

      validator = command_object.project.project_type.validator
      command_object.command = "#{URI.escape(validator)} #{URI.escape(project_type_params)} #{URI.escape(package_dir)}"

      command_object.timeout = 3600*10 # 10 hours by default
    end
  end

  def run
    super do

      command_object.status = Validate::Status::VALIDATING
      command_object.stdout = ""
      command_object.stderr = ""
      command_object.save

      (validator, params, package_dir) = command_object.command.split(/ /).map { |i| URI.unescape(i) }


      if !File.directory? package_dir then
        command_object.stderr = command_object.stderr + "Can't find extracted experiment directory #{package_dir}"
        command_object.status = Validate::Status::VALIDATION_FAILED
        command_object.save
        self.do_after
        return false
      end


      # If the root of the extracted package just contains a single dir, assume
      # the IDF is in that dir
      lookup_dir = package_dir
      if Dir.glob(File.join(lookup_dir, "*")).reject { |file| file =~ /\.chadoxml$/ }.size == 1 then
        entry = Dir.glob(File.join(lookup_dir, "*")).reject { |file| file =~ /\.chadoxml$/ }.first
        if File.directory? entry then
          lookup_dir = entry
        end
      end

      possible_idfs = Dir.glob(File.join(lookup_dir, "*.idf")) + Dir.glob(File.join(lookup_dir, "*IDF*")) + Dir.glob(File.join(lookup_dir, "*idf*"))
      if possible_idfs.empty? then
        command_object.stderr = command_object.stderr + "Can't find any IDF matching *.idf, *IDF* or *idf* in #{lookup_dir}"
        command_object.status = Validate::Status::VALIDATION_FAILED
        command_object.save
        self.do_after
        return false
      end


      idf_file = possible_idfs.first
      output_file = File.join(package_dir, "#{command_object.project.id}.chadoxml")

      run_command = "#{validator} #{params} #{idf_file} #{output_file} -n=#{Escape::shell_single_word(command_object.project.name)}"

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

          # Save the Validate object if it's been 2 seconds and the last chr read
          # from one of the pipes was a newline - application-side flushing, basically
#          if (Time.now - last_update) > 2 then
            if (!out_chr.nil? && (out_chr == "\n" || out_chr == "\r")) ||
              (!err_chr.nil? && (err_chr == "\n" || err_chr == "\r")) then
              command_object.save
              command_object.reload
              if command_object.status == Command::Status::CANCELING then
                # TODO: Oh no, interrupt!!!
              end
              last_update = Time.now
            elsif (Time.now - last_update) > 60*2 then
              # If it's been two minutes, write an update anyway
              command_object.save
              command_object.reload
              if command_object.status == Command::Status::CANCELING then
                # TODO: Oh no, interrupt!!!
              end
              last_update = Time.now
              last_update = Time.now
            end
#          end
        end

        command_object.save
        exitvalue = exitvaluechannel[0].read.to_i
        errormessage = sidechannel[0].read
        [ exitvalue, errormessage ]
      }

      # Errors?
      if command_object.stderr =~ /^\s*ERROR:/ then
        command_object.status = Validate::Status::VALIDATION_FAILED
        command_object.save
      end
      if (exitvalue != 0) then
        if errormessage.length > 0 then
          command_object.stderr = "#{exitvalue}:#{errormessage}"
          command_object.status = Validate::Status::VALIDATION_FAILED
          command_object.save
        else
          command_object.stderr += "Validator crashed! (See output.)"
          command_object.status = Validate::Status::VALIDATION_FAILED
          command_object.save
        end
      end

      # Validator exited, tack on newlines if they aren't already there
      command_object.stdout = command_object.stdout + "\n" unless command_object.stdout =~ /\n$/
      command_object.stderr = command_object.stderr + "\n" unless command_object.stderr =~ /\n$/
      command_object.status = Validate::Status::VALIDATED unless command_object.status == Validate::Status::VALIDATION_FAILED

      # Save one last time
      command_object.save
      return self.do_after
    end
  end
end
