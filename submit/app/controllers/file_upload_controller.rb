class FileUploadController < UploadController
  def initialize(options)
    super
    return unless options[:command].nil? # Set in CommandController if :command is given

    self.command_object = Upload::File.new(options)
    command_object.command = URI.escape(options[:source]) + " to " + URI.escape(options[:filename])
    command_object.timeout = 36000 # 10 hours by default
    command_object.save
  end
  def run
    super do
      retval = true
      (source, destfile) = command_object.command.split(/ to /).map { |i| URI.unescape(i) }
      do_before(:destfile => destfile)
      command_object.status = Upload::Status::UPLOADING
      command_object.save
      begin
        # Remove any files that are in the way of this upload
        File.delete(destfile) if File.exists?(destfile)

        if (command_object.timeout && command_object.timeout > 0) then
          Timeout::timeout(command_object.timeout) { FileUtils.copy(source, destfile) }
        else
          FileUtils.copy(source, destfile)
        end
        command_object.status = Upload::Status::UPLOADED
        command_object.save
      rescue Timeout::Error
        command_object.stderr = "Upload timed out! Took longer than #{command_object.timeout} seconds."
        command_object.status = Upload::Status::UPLOAD_FAILED 
        command_object.save
        retval = false
      rescue
        command_object.stderr = $!
        command_object.status = Upload::Status::UPLOAD_FAILED 
        command_object.save
        retval = false
      ensure
        retval = retval & do_after(:source => source, :destfile => destfile)
      end
      return retval
    end
  end
  protected
  def do_after(options = {})
    # Clean up
    File.delete(options[:source]) if !options[:source].blank? && File.exists(options[:source])
    return super
  end

end
