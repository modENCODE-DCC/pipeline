class UrlUploadController < UploadController
  def initialize(options)
    super
    @last_update = Time.now
    return unless options[:command].nil? # Set in CommandController if :command is given

    if block_given? then
      yield
      return unless self.command_object.nil?
    end
    self.command_object = Upload::Url.new(options)
    command_object.command = URI.escape(options[:source]) + " to " + URI.escape(options[:filename])
  end
  def run
    super do
      return yield if block_given?
      retval = true
      (upurl, destfile) = command_object.command.split(/ to /).map { |i| URI.unescape(i) }
      do_before(:destfile => destfile)
      command_object.status = Upload::Status::UPLOADING
      begin
        if (command_object.timeout && command_object.timeout > 0) then
          Timeout::timeout(command_object.timeout) { get_contents(upurl, destfile) }
        else
          get_contents(upurl, destfile)
        end
        command_object.status = Upload::Status::UPLOADED
        command_object.save
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
        do_after_val = 
        retval = retval & do_after(:destfile => destfile)
      end
      return retval
    end
  end

  def get_contents(upurl, destfile)
    begin
      OpenURI.open_uri( upurl, :content_length_proc => proc { |len| command_object.content_length = len; command_object.save }, :progress_proc => proc { |prog| self.update_uploader_progress_with_save = prog }
          ) { |result|
            ::File.open(destfile, "w") { |dfile|
              dfile.write(result.read)
            }
          }
    rescue
      raise CommandFailException.new("Failed to fetch URL #{upurl}")
    end
  end

  def update_uploader_progress_with_save=(prog)
    command_object.progress = prog
    if Time.now - @last_update > 2 then
      command_object.save
      @last_update = Time.now
    end
  end

end

