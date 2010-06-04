require 'escape'
require 'open4'

class RsyncUploadController < UploadController
  def initialize(options)
    super
    @last_update = Time.now
    @project = options[:project]
    return unless options[:command].nil? 
        # Set in CommandController if :command is given

    if block_given? then
      yield
      return unless self.command_object.nil?
    end
    self.command_object = Upload::Rsync.new(options)
    command_object.command = URI.escape(options[:source]) +
                            " to " + URI.escape(options[:filename])
  end

  def run
    super do
      return yield if block_given?
      retval = true
      # get source and destination
      (uprsync, destfile) = command_object.command.split(/ to /).map {
        |i| URI.unescape(i) }
      
      do_before(:destfile => destfile) # in UploadController
      command_object.status = Upload::Status::UPLOADING
      begin
        if (command_object.timeout && command_object.timeout > 0) then
          Timeout::timeout(command_object.timeout) {
            get_contents(uprsync, destfile) }
        else
          get_contents(uprsync, destfile)
        end
        command_object.status = Upload::Status::UPLOADED
        command_object.save
      rescue Timeout::Error
        command_object.stderr = "Rsync upload timed out! It took longer than" +
                                "#{command_object.timeout} seconds."
        command_object.status = Upload::Status::UPLOAD_FAILED
        command_object.save
      rescue CommandFailException
        command_object.stderr = $!.message
        command_object.status = Upload::Status::UPLOAD_FAILED
        command_object.save
        retval = false
      rescue
        command_object.stderr = $!
        command_object.status = Upload::Status::UPLOAD_FAILED
        command_object.save
        retval = false
      ensure
        # Destfile might have been updated, so get it again
        (uprsync, destfile) = command_object.command.split(/ to /).map {
           |i| URI.unescape(i) }
        retval = retval & do_after(:destfile => destfile)
      end
      return retval
    end
  end


  def do_after(options = {})
    super

    # Rexpand all active archives for this project
    unless command_object.failed? then
      PipelineController.new.queue_reexpand_project(command_object.project, command_object)
      CommandController.do_queued_commands
    end


  end
  # get_contents assumes that we are uploading only a single
  # file, via rsync daemon.  
  def get_contents(upuri, destfile)
    begin
      # Separate the filenames and paths
      upuri = URI.escape(upuri)
      dest_path = File.dirname(destfile)
      dest_name = File.basename(destfile)
      src_path = File.dirname(upuri)
      src_name = File.basename(upuri)
     
      # Set up temp directory with name = Project ID in the tmp folder
      # to upload into
      project_id = command_object.project.id
      begin
        tmp_path = RsyncUploadController::make_tmp_dir(project_id) 
      rescue Exception => e
        raise CommandFailException.new("No temporary upload folder could be made:\n #{e}")
        return
      end
      # rsync into the temp folder using original filename
      # To throttle for testing purposes, add flag "--bwlimit=X" with X = desired max kb/sec
      rsync_command = ["rsync", "-av", "--progress",
      upuri, "#{tmp_path}/"] 

      # Note: if this is changed to take the contents of a whole
      # directory, use src/'*' instead of src to avoid a permissions issue.
      logger.info "Running rsync with command: #{rsync_command.join(' ')}"
      status =
      Open4::popen4(*rsync_command) { |pid, stdin, stdout, stderr|
        
        # Read the output from the command and pass it to the 
        # command object to put in the status box as it appears
        expecting_input = true
        next_line = "" # Accumulate chars here
        status_output = "" # What to send to stdout
        while expecting_input
          begin         
            # Get input a character at a time
            next_char = stdout.read_nonblock(1)
            next_line += next_char
            # Send to output on newline or carriage return
            if (next_char == "\n") or (next_char == "\r") then
             # If it's a newline, the chars should remain -- accumulate in
             # status_output and update.
             if next_char == "\n" then
               status_output += next_line
               next_line = ""
             end
             # Otherwise, it's \r, they'll be overwritten, so leave them in next_line
              self.update_uploader_progress_with_save = status_output + next_line 
              next_line = ""
           end
          rescue EOFError # Out of input - we're done
            expecting_input = false
          rescue Errno::EAGAIN # Waiting for more input; not an error
          rescue Errno::EINTR # Interrupted System Call - should retry
          end
        end
        # Also get the stderr
        command_object.stderr = stderr.read.strip
      }
      logger.info "Status of rsync command: #{status}"
      unless status.to_i == 0 # If rsync failed, abort!
        raise CommandFailException.new("rsync command failed with exit code #\
#{status.to_i >> 8}: #{command_object.stderr}!")
      end
      # Rename the uploaded file to the expected destination filename
      move_source = File.join(tmp_path, src_name)
      move_target = File.join(dest_path, dest_name)
      logger.info "Moving from #{move_source} to #{move_target}"
      FileUtils.move(move_source, move_target)
      # Remove the temp dir, complaining if it doesn't exist or is nonempty
      RsyncUploadController.remove_tmp_dir(project_id)
    rescue Exception => e
      logger.warn "Exception in rsync uploader: #{e}"
      logger.error e
      logger.error e.backtrace
      command_object.status = Upload::Status::UPLOAD_FAILED
      command_object.save
      # Remove tmpdir, suppressing errors
      begin
        RsyncUploadController.remove_tmp_dir(project_id, true) 
      rescue
      end
      raise CommandFailException.new("Couldn't fetch #{upuri} via rsync:\n #{e}")
    end
  end

  # gbrowse_tmp:  Gets and returns the path to the temp folder from gbrowse.yml
  def self.gbrowse_tmp
    if File.exists? "#{RAILS_ROOT}/config/gbrowse.yml" then
       gbrowse_config = open("#{RAILS_ROOT}/config/gbrowse.yml"){ |f| 
        YAML.load(f.read) }
      return  gbrowse_config['tmp_dir']
    else
      raise "You need a gbrowse.yml file in your config/ directory /
with at least a tmp_dir in it."
    end
  end
  # make_temp_dir: Gets the path to the temporary folder from gbrowse.yml
  # and creates a temp. dir in it named {project ID}.
  # If the dir already exists, will cleanup (remove) it and make it again.
  # Returns full path to temporary dir created
  def self.make_tmp_dir(project_id)
   # Found tmp_dir -- get project ID
    gbrowse_tmp_dir = RsyncUploadController::gbrowse_tmp
    tmp_path = File.join(gbrowse_tmp_dir, "#{project_id}")
    # Remove dir if it's already there --it means something went wrong earlier
    if File.exists? tmp_path then
      logger.info "Removing folder #{tmp_path} so we can make it afresh"
      begin
        RsyncUploadController::remove_tmp_dir(project_id, true)
      rescue Exception => e
       raise CommandFailException.new("Couldn't remove old upload folder:\n #{e}")
      end
    end
    logger.info "Making temp upload folder #{tmp_path}"
    FileUtils.mkdir tmp_path
    # Return the path to the tmp_dir 
    return tmp_path  
  end

  # Removes the temp dir created in make_tmp_dir.
  # if cleanup = true, will not complain upon being asked to remove
  # nonexistant folder (for cleanup from exceptions in get_contents), and
  # will remove the dir even if it is nonempty.
  def self.remove_tmp_dir(project_id, cleanup = false)
    gbrowse_tmp_dir = RsyncUploadController::gbrowse_tmp
    tmp_path = File.join(gbrowse_tmp_dir, "#{project_id}")
    if File.exists? tmp_path then
      begin
        FileUtils.rmdir tmp_path # Try removing it normally
      rescue Errno::ENOTEMPTY
        unless cleanup then
          cleanup = true # To improve the deletion logger message below.
          logger.error "Rsync Upload: #{tmp_path} was nonempty when we tried to delete it--probably a\
 file move failed. Redeleting."
        end
        FileUtils.remove_dir tmp_path # Remove dir recursively
      end
      logger.info "Deleted #{"empty " unless cleanup}upload folder #{tmp_path}#{" and its \
contents" if cleanup}."
    else # The folder isn't there
      # Don't fail if we thought this might happen 
      raise Exception("Tried to delete temp dir #{tmp_path} but it doesn't exist!") unless cleanup 
    end
  end

 # Updates the uploader's status -- saves every two seconds
 def update_uploader_progress_with_save=(status)
    command_object.stdout = status
    if Time.now - @last_update > 2 then
      command_object.save
      @last_update = Time.now
    end
  end 
end
