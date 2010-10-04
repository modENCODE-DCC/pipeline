class FtpUploadController < UploadController
  def initialize(options)
    super
    @last_update = Time.now
    return unless options[:command].nil? # Set in CommandController if :command is given

    if block_given? then
      yield
      return unless self.command_object.nil?
    end
    self.command_object = Upload::Ftp.new(options)
    command_object.command = URI.escape(options[:source]) + " to " + URI.escape(options[:filename])
  end
  def run
    super do
      return yield if block_given?
      retval = true
      (upftp, destfile) = command_object.command.split(/ to /).map { |i| URI.unescape(i) }
      do_before(:destfile => destfile)
      command_object.status = Upload::Status::UPLOADING
      begin
        ftpMount = ActiveRecord::Base.configurations[RAILS_ENV]['ftpMount']
        upftp = File.expand_path(File.join(ftpMount, upftp))
        if upftp.start_with?(ftpMount) && File.file?(upftp) then
          # Get the file
          FileUtils.copy(upftp, destfile)
          if (File.file?(upftp)) then
            FileUtils.rm(upftp, :force => true)
          end
          command_object.status = Upload::Status::UPLOADED
          command_object.save
        else
          command_object.stderr = "Couldn't find source file in the FTP directory!"
          command_object.status = Upload::Status::UPLOAD_FAILED 
          command_object.save
          retval = false
        end
      rescue Timeout::Error
        command_object.stderr = "Upload timed out! Took longer than #{command_object.timeout} seconds."
        command_object.status = Upload::Status::UPLOAD_FAILED 
        command_object.save
        retval = false
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
        (upurl, destfile) = command_object.command.split(/ to /).map { |i| URI.unescape(i) }
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
end
