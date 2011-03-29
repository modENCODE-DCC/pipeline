class FileUploadReplacementController < FileUploadController
  def initialize(options)
    super do
      return unless options[:command].nil?

      self.command_object = Upload::FileReplacement.new(options)
      command_object.command = URI.escape(options[:source]) + " to " + URI.escape(options[:filename]) + " to " + URI.escape(options[:archive_name])
      command_object.timeout = 36000 # 10 hours by default
      command_object.save
    end
  end
  def run
    res = super
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
    cmd = "tar -czvf '#{absolute_desttgz.gsub(/'/, escape_quote)}'  -C '#{extracted_dir.gsub(/'/, escape_quote)}' '#{relative_file.gsub(/'/, escape_quote)}'"
    # TODO: Error handling
    result = `#{cmd} 2>&1`
    command_object.stderr = "#{command_object.stderr}\nCompressed #{result} to #{desttgz}"
    command_object.save
    return do_after(:destfile => absolute_desttgz)
  end
end
