class UrlUploadReplacementController < UrlUploadController
  def initialize(options)
    super do
      @last_update = Time.now
      return unless options[:command].nil?

      self.command_object = Upload::UrlReplacement.new(options)
      command_object.command = URI.escape(options[:source]) + " to " + URI.escape(options[:filename]) + " to " + URI.escape(options[:archive_name])
      command_object.save
    end
  end
  def run
    res = false
    super do
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
      end
      res = retval
    end
    return res if res == false
    # Okay, now file is in uploaded location, make a tarball of it
    escape_quote = "'\\''"
    project_dir = PipelineController.new.path_to_project_dir(command_object.project)
    extracted_dir = File.join(project_dir, "extracted")
    (upurl, destfile, desttgz) = command_object.command.split(/ to /).map { |i| URI.unescape(i) }
    absolute_desttgz = File.join(project_dir, desttgz)
    throw :relative_paths_not_okay unless destfile.start_with?(extracted_dir)
    unless File.exists?(destfile) then
      command_object.stderr = "#{command_object.stderr}\nCouldn't find uploaded file #{destfile}"
      command_object.status = Upload::Status::UPLOAD_FAILED
      command_object.save
      return false
    end
    relative_file = destfile.sub(extracted_dir, "")
    relative_file.gsub!(/^\/*/, '')
    cmd = "tar -czvf '#{absolute_desttgz.gsub(/'/, escape_quote)}'  -C '#{extracted_dir.gsub(/'/, escape_quote)}' #{relative_file.gsub(/'/, escape_quote)}"
    # TODO: Error handling
    result = `#{cmd} 2>&1`
    command_object.stderr = "#{command_object.stderr}\nCompressed #{result} to #{desttgz}"
    command_object.save
    return do_after(:destfile => absolute_desttgz)
  end
  def get_contents(upurl, destfile)
    begin
      upurl = URI.escape(upurl)
      OpenURI.open_uri( upurl, :no_verify_peer => true, :content_length_proc => proc { |len| command_object.content_length = len; command_object.save }, :progress_proc => proc { |prog| self.update_uploader_progress_with_save = prog }
          ) { |result|
            content_disposition_file = result.meta["content-disposition"]
            content_disposition_file = content_disposition_file.split(";").find { |h| h =~ /^\s*filename=/ } unless content_disposition_file.nil?
            content_disposition_file = content_disposition_file.split("=").last unless content_disposition_file.nil?
            content_disposition_file.gsub!(/^"|"$/, "")
            if !content_disposition_file.nil? && content_disposition_file.length > 0 then
              project_archive = command_object.project.project_archives.all.find { |pa| File.basename(pa.file_name) == File.basename(destfile) }
              (source, dest, rest) = command_object.command.split(" to ")

              dest = File.join(File.dirname(URI.unescape(destfile)), File.basename(content_disposition_file))
              logger.debug "Using content-disposition filename #{dest} instead of #{destfile}"

              unless project_archive.nil? then
                project_archive.file_name = content_disposition_file
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
          }
    rescue Exception => e
      logger.warn "Rescued upload exception #{e}"
      logger.error e
      command_object.status = Upload::Status::UPLOAD_FAILED 
      command_object.save
      raise CommandFailException.new("Failed to fetch URL #{upurl}")
    end
  end


end
