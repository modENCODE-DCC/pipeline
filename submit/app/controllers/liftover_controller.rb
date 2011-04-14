require 'find'
require 'escape'
class LiftoverController < CommandController
  
  # An array of allowable genome builds to lift from or to
  GENOME_BUILDS = %w{170 180 190 200 210 220};
  
  # A wrapper for sending things to command_object's stdout
  def debug(input)
    # puts input
    if (debug?) then
      command_object.stdout += input 
      command_object.save
      $stderr.puts input
    end
  end
  
  def debug?
    return @debug
  end
  def debug=(debugging)
    @debug = debugging
  end

  # Constructs the liftover command
  def liftover_command(srcpath, destpath, srcver, destver)
    path_to_liftover = File.join(RAILS_ROOT, "script", "liftover")
    base_cmd = "java -jar #{File.join(path_to_liftover, "WormbaseLiftover.jar")}"

    #base_cmd = "java " +
    #  "-cp #{File.join(path_to_liftover, "liftover/bin/")}:#{File.join(path_to_liftover, "picard/bin/")}:#{File.join(path_to_liftover, "liftover/lib/JSAP-2.1.jar")} " +
    #  "org.modencode.tools.liftover.Liftover"
   
    filetype_flag = case File.extname(srcpath.downcase)
      when ".gff", ".gff3"
        "-g"
      when ".sam"
        "-s"
      when ".wig", ".gr"
        "-w"
      when ".bed"
        "-b"
      else
        "-x"
        command_object.stdout += "\n#{Liftover::ERR_BEG}Wanted to lift #{File.basename srcpath
          } but couldn't detect type!#{Liftover::ERR_END}"
        command_object.stdout += "\nCan't lift #{File.basename srcpath}--type can't be detected from extension"
        # You'll never get here from normal user-running of program
        return false
    end

    cmd = [
      base_cmd, filetype_flag, Escape.shell_command(srcpath),
      "-1", srcver, "-2", destver, "-o", Escape.shell_command(destpath)
    ].join(" ")

    return cmd
  end

  # Destroy a project_archive if one was created,
  # along with associated tarfiles
  # Also re-expand the project automatically?
  def cleanup_failed_lift(liftover_archive)
    # Destroy a ProjectArchive if one was made, and the corresponding tar or tar.gz
    command_object.stdout += "\n   Destroying the liftover's ProjectArchive"
    project_dir = PipelineController.new.path_to_project_dir(command_object.project)
    archive_tar_gz = File.join(project_dir, liftover_archive.file_name.to_s) 
    archive_tar = archive_tar_gz.nil? ? "" : archive_tar_gz.sub( /\.gz$/, "" )
    # liftover failed === validation failed
    liftover_archive.destroy
    if File.file?(archive_tar_gz) then
      command_object.stdout += "\n   Destroying #{archive_tar_gz}"
      FileUtils.remove_file(archive_tar_gz)
    end
    if File.file?(archive_tar) then
      command_object.stdout += "\n   Destroying #{archive_tar}"
      FileUtils.remove_file(archive_tar)
    end
  end
  
  
  def initialize(options = {})
    @debug = false # here goes...
    super
    return unless options[:command].nil?
    # If they don't specify whether archiving (ie from console), just update the project anyway 
    logger.error "Must specify if updating or lifting an archive" if options[:archive_only].nil?
    # Make sure the source and dest are appropriate values 
    unless (  LiftoverController::GENOME_BUILDS.include? options[:source] ) && 
      ( LiftoverController::GENOME_BUILDS.include? options[:dest] ) then
      logger.error "Invalid starting or ending build--can't run liftover."
      return
    end
    self.command_object = Liftover.new(options)
    command_object.command = options[:source].to_s + " to " + options[:dest].to_s
    command_object.command += " archive" if options[:archive_only]
    command_object.stdout = command_object.stderr = ""
    command_object.save
    # NOTE : this will trust that the project
    # is, in fact, in the source genome build
  end

  # Returns a list of the full paths of files within dir
  # that could be lifted based on extension
  def self.find_liftable_files(dir)
    files_to_convert = []
    Find.find(dir) { |found|
      next if found =~ /\/ws\d+\//i # Skip any existing lifted folders
      found_base = File.basename(found)
      if ((found_base =~ /\.(gff3?|sam|wig|gr|bed)$/i) && (found_base !~ /^\./)) then
        # get files by extension, and skip any "hidden" dotfiles
        files_to_convert.push found
      end
    }
    files_to_convert
  end

  # Run a command with open5, logging output to command_object.
  # returns (exitcode, errormessage). Copied from Validate code.
  def system_with_logging(system_command)
    last_update = Time.now
    (exitvalue, errormessage) = Open5.popen5(system_command) { |stdin, stdout, stderr, exitvaluechannel, sidechannel|
      # Send both stdout and stderr to the command's stdout
      cmd_out = ""
      cmd_err = Liftover::ERR_BEG 
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
        cmd_out += out_chr unless out_chr.nil?
        cmd_err += err_chr unless err_chr.nil?

        # If we've gotten a newline, write the line
        if (out_chr == "\n" || out_chr == "\r") then
          command_object.stdout += cmd_out
          cmd_out = ""
        end
        if (err_chr == "\n" || err_chr == "\r") then
          command_object.stdout += cmd_err + Liftover::ERR_END
          cmd_err = Liftover::ERR_BEG
        end

        # Save the Liftover object if it's been 2 seconds and the last chr read
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
      end # while result
      # Write any remaining chars
      command_object.stdout += cmd_out
      command_object.stdout += cmd_err + Liftover::ERR_END unless cmd_err == Liftover::ERR_BEG # Only write nonempty err

      command_object.save
      exitvalue = exitvaluechannel[0].read.to_i
      errormessage = sidechannel[0].read
      [ exitvalue, errormessage ]
    }
    [exitvalue, errormessage]
  end
  
  # Search filename for comments that were included by the liftover process,
  # and insert them into the Liftover's stderr.
  def find_liftover_comments(fullpath)
    liftover_comment = /^\s*#liftover:/ # The string to check for
    lifted = File.open(fullpath)
    found_comment = false
    while line = lifted.gets
      if line =~ liftover_comment then
        found_comment = true
        command_object.stderr += ">> #{line.sub("#liftover: ", "")}"
        # TODO : also include the following un-commented lines
        # ie, the next line for most thing, or the entire next
        # fasta-feature.
      end
    end
    lifted.close
    command_object.stderr += "(none)\n" unless found_comment 
    command_object.save 
  end

  
  # Run assumes that a) the project being lifted is worm and
  # b) the project is currently in the WS it's given. Checks need to be made elsewhere.
  def run
    super do
      command_object.status = Liftover::Status::LIFTING
      command_object.stdout = command_object.stderr = ""
      command_object.stdout += "Running liftover from #{command_object.command.gsub(/(\d+)/, 'WS\1')}."
      command_object.save
      
      project_dir = PipelineController.new.path_to_project_dir(command_object.project)
      extracted_dir = File.join(project_dir, "extracted")
      unless File.directory?(extracted_dir) then
        command_object.stdout += "\nCan't find extracted directory at #{project_dir} to lift files!"
        return false
      end
      (sourceWS, destWS) = command_object.command.split(" to ")
      # Split off a trailing " archive" if we're making an archive
      archive_only = destWS =~ /archive/ # Either a number or nil.
      destWS.sub! " archive", "" if archive_only
      debug "Lifting into an archive! " if archive_only

      unless sourceWS && destWS then
        command_object.stdout += "\n#{Liftover::ERR_BEG}Cannot lift without a non-nil source and" + 
        " destination genome build! Source is #{sourceWS.inspect} and" +
        " destination is #{destWS.inspect}#{Liftover::ERR_END}."
        command_object.status = Liftover::Status::LIFTOVER_FAILED
        command_object.save
        return false
      end
      source_dir = File.join(extracted_dir, "ws#{sourceWS}")
      dest_dir = File.join(extracted_dir, "ws#{destWS}")

      # Find files that'll be converted!
      files_to_convert = LiftoverController.find_liftable_files(extracted_dir)

      if files_to_convert.empty? then
        logger.info "Didn't find any files needing lifting in project #{command_object.project_id}"
        command_object.stdout += "\nDidn't find any files needing lifting in" +
          " project #{command_object.project_id}"
        # no files need be converted -- do nothing
        command_object.status = Liftover::Status::LIFTOVER_FAILED
        command_object.save
        return true # for now
      end

      # Make WSdest folder to hold lifted files temporarily.
      # TODO : Should complain if there's the same folder [possibly with different caps]?
      if File.exist? dest_dir then
        command_object.stdout += "\n#{Liftover::ERR_BEG}Liftover folder #{dest_dir} exists in "+
          "extracted&mdash;the project may have been lifted already. Try deactivating the archive "+
          "containing the #{dest_dir} folder.#{Liftover::ERR_END}"
        command_object.status = Liftover::Status::LIFTOVER_FAILED
        command_object.save
        return false
      end
      FileUtils.mkdir(dest_dir) unless debug? # Lift into a different dir, for now
      debug "Would make #{dest_dir} to lift into."
  
      # Also make dir that originals will be copied into late
      if File.exist? source_dir then
        truncated_source_dir = source_dir.sub(/.*?extracted\//, "")
        command_object.stdout += "\n#{Liftover::ERR_BEG}Couldn't make dir #{truncated_source_dir} " +
          "to store original files: it already exists! There is likely an active archive that " +
          "has already been lifted from WS#{sourceWS}.#{Liftover::ERR_END}" 
        command_object.status = Liftover::Status::LIFTOVER_FAILED
        command_object.save
        return false
      end
      FileUtils.mkdir(source_dir) unless ( debug? || archive_only )
      debug "Would make #{source_dir} for originals" if !archive_only

      lifted_files = [] # Path to files successfully lifted
      # Lift each file!
      files_to_convert.each{|src_fullpath|
        debug "Now lifting #{src_fullpath}\n"
        # Make the directory tree in the destination ws dir if necessary
        # also make it in the source WS dir now - we'll copy those files later.

        path_to_new = dest_dir
        path_to_src_archive = source_dir 

        localpath = src_fullpath.sub(extracted_dir + "/", "") # Relative path to file
        path_to_new = File.dirname(File.join(dest_dir, localpath)) # Absolute path to dest dir
        path_to_src_archive = File.dirname(File.join(source_dir, localpath)) # Absolute path to source archive
        dest_fullpath = File.join(dest_dir, localpath) # Absolute path to dest file

        if debug? then
          debug "Would make source subdir #{path_to_src_archive}"
          debug "Would make subdirectory #{path_to_new}"
        else
          FileUtils.mkpath(path_to_new)
          FileUtils.mkpath(path_to_src_archive) unless archive_only
        end

        # make the liftover command
        liftover_cmd = liftover_command(src_fullpath, dest_fullpath, sourceWS, destWS)
        command_object.stdout += "\n   Now lifting #{localpath}\n" # Show containing folders
        exitvalue = errormessage = nil
        if debug? then
          debug "\nConstructed liftover command: #{liftover_cmd}"
          exitvalue = 0 # Pretend it works when debugging
        else
          # Run command & get output to store in stderr/stdout -- copied from Validate. 
          (exitvalue, errormessage) = system_with_logging(liftover_cmd) 
          lifted_files.push dest_fullpath
        end
        unless exitvalue == 0 then
          # Error!
          command_object.stdout += "\n#{Liftover::ERR_BEG}Error lifting #{src_fullpath}"
          command_object.stdout += "\nAn error was detected! Liftover will now exit.#{Liftover::ERR_END}"
          command_object.stdout += "\nThis project should be re-expanded."
          command_object.status = Liftover::Status::LIFTOVER_FAILED
          command_object.save
          return false
        end 
        # After lifting the file, grep through it to find any internal changes and report them
        # to the stderr field.
        # Put the name of the file & the comments inside it
        command_object.stderr += "\nFile #{localpath}:\n"
        find_liftover_comments(dest_fullpath)
      }
      
      # Lifting finished! Clean up based on whether we're making a lifted
      # archive or updating the project to a new WS.
      command_object.stdout += "\nFinished lifting files ; archiving...\n"
  
      files_to_archive = Array.new
      if archive_only then
        files_to_archive = lifted_files # files_to_archive = the files in the new destWS only
      else
        command_object.stdout += "\nMoving originals to #{sourceWS} and lifted files to main project..."
        files_to_archive = files_to_convert # The files in the main dir (lifted versions )
        #  files_to_archive.push source_dir # NOT YET! Move the files first!
       
        # move originals from main to sourceWS folder
        files_to_convert.each{|src_fullpath|
          # Copy them into a tree
          # The appropriate subfolders were made earlier, along with dest's subfolders
          src_copy_path = src_fullpath.sub(extracted_dir, source_dir)
          command_object.stdout += "\n   Moving #{File.basename(src_fullpath)} to WS#{sourceWS} directory."
          FileUtils.mv src_fullpath, src_copy_path, :noop => debug? , :verbose => debug?
        }     
      
        # Also, move the lifted files from destWS into the main dir
        files_to_convert.each{|main_dir_file|
          source_lifted = main_dir_file.sub(extracted_dir , dest_dir)
          # Check that we aren't clobbering any files -- they should have already been moved!
          if File.exist? main_dir_file then
            command_object.stdout += "\n#{Liftover::ERR_BEG}Found file #{main_dir_file} that should have been moved!"
            command_object.stdout += Liftover::ERR_END
            # Assume something went wrong earlier and abort
            command_object.stdout += "\nProblem moving lifted files! Liftover will now exit."
            command_object.stdout += "\nThis project should be re-expanded."
            command_object.status = Liftover::Status::LIFTOVER_FAILED 
            command_object.save
            return false
          end
          command_object.stdout += "\n   Moving #{File.basename(source_lifted)} to main directory from WS#{destWS}."
          FileUtils.mv source_lifted, main_dir_file, :noop => debug?, :verbose => debug?
        }     
      
        # The temporary dest directory will be deleted when the project is re-expanded
        files_to_archive.push source_dir # Make sure to archive the originals too!
      end # end if archive_only
      # Make the path local to the extracted dir
      files_to_archive.map!{|fpath| fpath.sub(extracted_dir + "/", "")}
      
      # Create the ProjectArchive
      tar_basename = archive_only ? "Files_lifted_to_WS#{destWS}.tar" : 
          "Project_lifted_to_WS#{destWS}.tar" 
      
      unless debug? then
        (archive = Project.find(command_object.project_id).project_archives.new).save 
        tar_filename = "#{"%03d" % archive.attributes[archive.position_column]
                              }_#{tar_basename}"
        archive.file_name = "#{tar_filename}.gz" # gzip will append .gz 
        archive.file_date = Time.now
        archive.is_active = ! archive_only
        archive.comment = archive_only ? 
          "Archive of files lifted to WS#{destWS} from WS#{sourceWS}." :
          "Lifts this project from WS#{destWS} to WS#{sourceWS}."
        archive.save
        
      else
        tar_filename = "XXX#{tar_basename}"
        debug "Would create PA with #{tar_filename}!"
      end
     
      command_object.stdout +=  "\nCreating .tar.gz archive of files...\n"
      tarfile = File.join(project_dir, tar_filename)

      FileUtils.cd extracted_dir
      tarball_cmd = "tar -cvf #{tarfile}"

      # Add each file to the tar separately and zip them at the end
      # to prevent the call from having too many characters
      files_to_archive.each{|filepath|
        tar_one_file = "#{tarball_cmd} \"#{filepath}\"" 
        (evalue, errmsg) = system_with_logging(tar_one_file) unless debug?
        evalue = 0 if debug?
        unless evalue == 0 then
          # Everything lifted fine, but there's some problem archiving them.
          command_object.stdout += "\nError while creating the archive!"
          command_object.stdout += "\nAn error was detected! Liftover will now exit."
          # Delete the lifted directories
          cleanup_failed_lift(archive)
        end
        tarball_cmd = "tar -rvf #{tarfile}" # For all but the first, append to existing tar
        debug tar_one_file
      }
      # Then zip it with gzip!
      gzip_cmd = "gzip #{tarfile}"
      debug gzip_cmd
      (evalue, errmsg) = system_with_logging(gzip_cmd) unless debug?
    
      tarfile += ".gz"
      
      unless debug? then
        archive.file_size = File.size(tarfile) 
        archive.status = ProjectArchive::Status::NOT_EXPANDED
        archive.signature = PipelineController.new.generate_file_signature(tarfile)
        archive.save
      end
      command_object.stdout += "\nLiftover has completed successfully!\n"
      command_object.status = Liftover::Status::LIFTED
      command_object.save
    end # end of super do 
  end
end
