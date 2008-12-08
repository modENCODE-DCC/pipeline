class UnloadIdf2chadoxmlController < UnloadController
  def initialize(options)
    super do
      return unless options[:command].nil?

      self.command_object = UnloadIdf2chadoxml.new(options)
      project_unload_params = command_object.project.project_type.unload_params || ''
      package_dir = File.join(ExpandController.path_to_project_dir(command_object.project), "extracted")

      unloader = command_object.project.project_type.unloader
      command_object.command = "#{URI.escape(unloader)} #{URI.escape(project_unload_params)} #{URI.escape(package_dir)}"

      command_object.timeout = 3600/2 # 30 minutes by default
    end
  end

  def run
    super do

      command_object.status = Unload::Status::UNLOADING
      command_object.stdout = ""
      command_object.stderr = ""
      command_object.save

      (unloader, params, package_dir) = command_object.command.split(/ /).map { |i| URI.unescape(i) }

      if !File.directory? package_dir then
        command_object.stderr = command_object.stderr + "Can't find extracted experiment directory #{package_dir}. Already deleted?"
        command_object.status = Unload::Status::UNLOADED
        command_object.save
        self.do_after
        return true
      end

      # Use the same code as ValidateIdf2chadoxmlController to figure out where the output XML is
      # If the root of the extracted package just contains a single dir, assume
      # the IDF is in that dir
      lookup_dir = package_dir
      if Dir.glob(File.join(lookup_dir, "*")).size == 1 then
        entry = Dir.glob(File.join(lookup_dir, "*")).first
        if File.directory? entry then
          lookup_dir = entry
        end
      end

      possible_idfs = Dir.glob(File.join(lookup_dir, "*.idf")) + Dir.glob(File.join(lookup_dir, "*IDF*")) + Dir.glob(File.join(lookup_dir, "*idf*"))
      if possible_idfs.empty? then
        command_object.stderr = command_object.stderr + "Can't find any IDF matching *.idf, *IDF* or *idf* in #{lookup_dir}"
        command_object.status = Unload::Status::UNLOAD_FAILED
        command_object.save
        self.do_after
        return false
      end

      idf_file = possible_idfs.first
      output_file = idf_file + ".chadoxml"
      schema = "modencode_experiment_#{command_object.project.id}"

      run_command = "#{unloader} #{params} #{database} -s \"#{schema}\" #{output_file}"

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
      if (exitvalue != 0) then
        command_object.stderr = command_object.stderr + "\n#{exitvalue}:#{errormessage}"
        command_object.status = Unload::Status::UNLOAD_FAILED
        command_object.save
      end

      # Validator exited, tack on newlines if they aren't already there
      command_object.stdout = command_object.stdout + "\n" unless command_object.stdout =~ /\n$/
      command_object.stderr = command_object.stderr + "\n" unless command_object.stderr =~ /\n$/
      command_object.status = Unload::Status::UNLOADED unless command_object.status == Unload::Status::UNLOAD_FAILED

      # Save one last time
      command_object.save
      return self.do_after
    end
  end

  private
  def database
    if File.exists? "#{RAILS_ROOT}/config/idf2chadoxml_database.yml" then
      db_definition = open("#{RAILS_ROOT}/config/idf2chadoxml_database.yml") { |f| YAML.load(f.read) }

      args = "-d=\"#{db_definition['perl_dsn']}\""
      args << " -user=\"#{db_definition['user']}\"" if db_definition['user']
      args << " -password=\"#{db_definition['password']}\"" if db_definition['password']
      return args
    else
      raise Exception("You need an idf2chadoxml_database.yml file in your config/ directory with at least a Perl DBI dsn.")
    end
  end
end

