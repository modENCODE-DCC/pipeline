require 'openuri-patch'
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
      PipelineController.new.queue_reexpand_project(command_object.project)
      CommandController.do_queued_commands
    end
  end

  def get_contents(upurl, destfile)
    begin
      upurl = URI.escape(upurl)
      globally_visible_result = nil
      OpenURI.open_uri( upurl, :no_verify_peer => true, :content_length_proc => proc { |len| command_object.content_length = len; command_object.save }, :progress_proc => proc { |prog| self.update_uploader_progress_with_save = prog }
          ) { |result|
            globally_visible_result = result
            content_disposition_file = result.meta["content-disposition"]
            content_disposition_file = content_disposition_file.split(";").find { |h| h =~ /^\s*filename=/ } unless content_disposition_file.nil?
            content_disposition_file = content_disposition_file.split("=").last unless content_disposition_file.nil?
            content_disposition_file.gsub!(/^"|"$/, "") unless content_disposition_file.nil?
            if !content_disposition_file.nil? && content_disposition_file.length > 0 then
              project_archive = command_object.project.project_archives.all.find { |pa| File.basename(pa.file_name) == File.basename(destfile) }
              (source, dest, rest) = command_object.command.split(" to ")

              logger.debug "Getting prefix for #{dest}"
              prefix = File.basename(destfile).match(/^\d+_/)
              prefix = prefix.nil? ? "" : prefix[0]
              dest = File.join(File.dirname(URI.unescape(destfile)), "#{prefix}#{File.basename(content_disposition_file)}")
              logger.debug "Using content-disposition filename #{dest} instead of #{destfile}"

              unless project_archive.nil? then
                project_archive.file_name = File.basename(dest)
                project_archive.save
              end

              rest = [] if rest.nil?
              command_object.command = ([source, URI.escape(dest)] + rest).join(" to ")
              command_object.save

              destfile = dest
            end

            ::File.open(destfile, "w") { |dfile|
              dfile.write(result.read)
            }
            if (result.is_a?(Tempfile)) then
              begin
                result.close!
              rescue
              end
            end
          }
    rescue Exception => e
      logger.warn "Rescued upload exception #{e}"
      logger.error e
      logger.error e.backtrace
      command_object.status = Upload::Status::UPLOAD_FAILED 
      command_object.save
      begin 
        globally_visible_result.close!
      rescue
      end
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

