class FileUploadController < UploadController
  def initialize(options)
    super
    return unless options[:command].nil? # Set in CommandController if :command is given

    if block_given? then
      yield
      return unless self.command_object.nil?
    end
    self.command_object = Upload::File.new(options)
    command_object.command = URI.escape(options[:source]) + " to " + URI.escape(options[:filename])
    command_object.timeout = 36000 # 10 hours by default
    command_object.save
  end
  def run
    super do
      retval = true
      (source, destfile) = command_object.command.split(/ to /).map { |i| URI.unescape(i) }
      if source == destfile then
        # This must be a placeholder command for a browser upload
        command_object.status = Upload::Status::UPLOADED
        command_object.save
        return self.class.ancestors[1].instance_method(:do_after).bind(self).call(:source => source, :destfile => destfile)
      end
      do_before(:destfile => destfile)
      command_object.status = Upload::Status::UPLOADING
      command_object.save
      begin
        # Remove any files that are in the way of this upload unless it's already the right file
        unless source == destfile
          File.delete(destfile) if File.exists?(destfile) 

          if (command_object.timeout && command_object.timeout > 0) then
            Timeout::timeout(command_object.timeout) { FileUtils.copy(source, destfile) }
          else
            FileUtils.copy(source, destfile)
          end
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
    unless options[:source] == options[:destfile] then
      File.delete(options[:source]) if !options[:source].blank? && File.exists?(options[:source])
    end
    super
  end

end

