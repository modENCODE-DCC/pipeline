class ExpandController < CommandController
  def initialize(options)
    super
    return unless options[:command].nil? # Set in CommandController if :command is given

    self.command_object = Expand.new(options)
    command_object.command = options[:filename]
    command_object.timeout = options[:timeout].blank? ? 1200 : options[:timeout] # 20 minutes by default
  end

  def run
    super do
      retval = true
      command_object.status = Expand::Status::EXPANDING
      command_object.save


      # Create or find then save a ProjectArchive for tracking this expansion
      project_archive = command_object.project.project_archives.find_by_file_name(command_object.command)
      do_before(:archive => project_archive)

      if project_archive.nil? then
        project_archive = command_object.project.project_archives.new({ :file_name => command_object.command })
      end
      project_archive.status = ProjectArchive::Status::EXPANDING
      project_archive.file_size = File.size(File.join(path_to_project_dir, command_object.command))
      project_archive.file_date = Time.now
      project_archive.save

      begin
        if prep_one_archive(project_archive) then
          recursively_process_archive(project_archive)
          command_object.status = Expand::Status::EXPANDED
          project_archive.status = ProjectArchive::Status::EXPANDED
          project_archive.save
        else
          command_object.status = Expand::Status::EXPAND_FAILED
          # Destroy the ProjectArchive if it's not going to be able to expand
          project_archive.destroy
        end
      rescue Errno::EACCES, Errno::EEXIST
        # Any file exception here means the entire unarchiving process has failed
        # Delete the project archive (dependents will auto-destroy)
        project_archive.destroy
        # Delete extracted files directory if it exists
        ExpandController.remove_extracted_folder(project_archive)
        # Set the expansion status
        command_object.status = Expand::Status::EXPAND_FAILED
        retval = false
      ensure
        # Always delete temporary upload folder if it exists
        upload_dir = File.join(path_to_project_dir, "upload_#{project_archive.attributes[project_archive.position_column]}")
        begin FileUtils.remove_dir upload_dir if File.directory? upload_dir rescue nil end
        begin command_object.save rescue nil end
        retval = retval ? do_after(:archive => project_archive) : false
      end
      return retval
    end
  end

  def do_before(options = {})
    if options[:archive] then
      pa = options[:archive]
      pa.status = ProjectArchive::Status::NOT_EXPANDED
      pa.save
      pa.project_files.each do |pf|
        pf.destroy
      end

      pa.project.status = Expand::Status::EXPANDING
      pa.project.save
    end
  end

  def do_after(options = {})
    retval = true
    project_archive = options[:archive]
    return unless project_archive
    if self.status == Expand::Status::EXPAND_FAILED then
      project_archive.status = ProjectArchive::Status::EXPAND_FAILED
      project_archive.project.status = Expand::Status::EXPAND_FAILED
      retval = false
    else
      project_archive.status = Expand::Status::EXPANDED
      project_archive.save

      expand_commands = project_archive.project.commands.find_all_by_type(command_object.class.name)
      unless (expand_commands.find_all { |e| e.status == Expand::Status::EXPANDING || e.status == Expand::Status::QUEUED }.size > 0) then
        # Do not complete expansion unless all Expand objects have been expanded
        project_archive.project.status = Expand::Status::EXPANDED
      end

    end
    project_archive.project.save
    return retval
  end
  def self.remove_extracted_folder(project_archive)
    extract_dir = File.join(path_to_project_dir(project_archive.project), "extracted")
    begin FileUtils.remove_dir extract_dir if File.directory? extract_dir rescue nil end
  end
  def self.path_to_project_dir(project)
    # the expand_path method resolves this relative path to full absolute path
    File.expand_path("#{ActiveRecord::Base.configurations[RAILS_ENV]['upload']}/#{project.id}")
  end
  private
  def path_to_project_dir
    ExpandController.path_to_project_dir(command_object.project)
  end
  def prep_one_archive(project_archive)
    # make sure parent paths exist
    project_dir = path_to_project_dir

    # Fail if the archive passed in does not exist
    file_name = project_archive.file_name
    if !File.exist?(File.join(path_to_project_dir, file_name)) then
      command_object.stderr = "Cannot find file #{file_name} in project directory #{project.id}/ for project #{project.name} to expand." 
      command_object.status = Expand::Status::EXPAND_FAILED
      command_object.save
      return false
    end

    # Make a temporary directory to unpack and merge into
    upload_dir = project_dir+"/upload_#{project_archive.attributes[project_archive.position_column]}"
    begin
      FileUtils.remove_dir upload_dir if File.directory? upload_dir 
      Dir.mkdir(upload_dir, 0775)
    rescue
      # Fail expansion if we couldn't make the temp directory
      command_object.stderr = "Error creating folder for uploaded package."
      command_object.status = Expand::Status::EXPAND_FAILED
      command_object.save
      return false
    end

    # Extract archive file in file_name into the temporary directory upload_dir
    cmd = makeUnarchiveCommand(upload_dir, file_name)
    timeout = 3600
    result = ""
    begin
      if (command_object.timeout && command_object.timeout > 0) then
        Timeout::timeout(command_object.timeout) { result = `#{cmd}` }
      else
        result = `#{cmd}`
      end
    rescue Timeout::Error
      command_object.stderr = "Error extracting uploaded file:<br/>\n#{result}"
      command_object.status = Expand::Status::EXPAND_FAILED
      begin FileUtils.remove_dir upload_dir if File.directory? upload_dir rescue command_object.stderr += "<br/>\nCouldn't remove temporary upload directory." end
      return false
    ensure
      # Remove temporary directory if expansion fails
      command_object.save
    end
    if $?.exitstatus != 0
      command_object.stderr = "Error extracting uploaded file:<br/>\n#{result}"
      command_object.status = Expand::Status::EXPAND_FAILED
      begin FileUtils.remove_dir upload_dir if File.directory? upload_dir rescue command_object.stderr += "<br/>\nCouldn't remove temporary upload directory." end
      command_object.save
      return false
    else
      command_object.stdout = "#{result}"
      command_object.save
    end

    return true
  end
  def makeUnarchiveCommand(upload_dir, filename)
    # handle unzipping the archive
    path_to_file = File.join(path_to_project_dir, filename)
    if ["zip", "ZIP"].any? {|ext| filename.ends_with?("." + ext) }
      cmd = "unzip -o  #{path_to_file} -d #{upload_dir}"   # .zip 
    else
      if ["gz", "GZ", "tgz", "TGZ"].any? {|ext| filename.ends_with?("." + ext) }
        cmd = "tar -xzvf #{path_to_file} -C #{upload_dir}"  # .gz .tgz gzip 
      else  
        cmd = "tar -xjvf #{path_to_file(filename)} -C #{upload_dir}"  # .bz2 bzip2
      end
    end
  end
  def recursively_process_archive(project_archive, path_in_archive = "")
    # Create ProjectFiles for each file in the expanded project_archive
    # Get folder to merge files into
    extract_dir = File.join(path_to_project_dir, "extracted")
    Dir.mkdir(extract_dir) unless File.directory?(extract_dir)

    # Get folder that files have been extracted to
    upload_dir = File.join(path_to_project_dir, "upload_#{project_archive.attributes[project_archive.position_column]}")
    current_working_path = path_in_archive.empty? ? upload_dir : File.join(upload_dir, path_in_archive)

    # Recurse through all the directories (skip . and ..)
    Dir.entries(current_working_path).reject { |f| f == '.' || f == '..' }.
      each do |current_entry| 
      current_entry_path = File.join(current_working_path, current_entry)
      relative_entry_path = path_in_archive.empty? ? current_entry : File.join(path_in_archive, current_entry)

      if File.directory? current_entry_path then
        # Recurse through directories
        move_to_dir = File.join(extract_dir, relative_entry_path)
        Dir.mkdir(move_to_dir) unless File.directory? move_to_dir
        recursively_process_archive(project_archive, relative_entry_path)

      elsif File.file? current_entry_path then
        # Move files into project directory
   
        # Set as deleted any existing ProjectFile records for this file
        # These may exist from a previous archive and are being overwritten
        project_archive.project.project_archives.each { |pa|
          pf = ProjectFile.find_by_project_archive_id_and_file_name(pa, relative_entry_path)
          if pf then
            if project_archive == pa then
              pf.destroy
            else
              pf.is_overwritten = true
              pf.save
            end
          end
        }

        # Create our new ProjectFile entry
        (project_file = project_archive.project_files.new(
          :file_name => relative_entry_path,
          :file_size => File.size(current_entry_path),
          :file_date => File.ctime(current_entry_path)
        )).save

        # Move the file!
        new_entry_path = File.join(extract_dir, relative_entry_path)
        # Don't rescue rename here errors, because the whole process has effectively failed
        File.rename(current_entry_path, new_entry_path);
      end
    end

    if path_in_archive.empty? then
      # Root level, go ahead and delete the upload folder
      begin FileUtils.remove_dir upload_dir if File.directory? upload_dir rescue nil end
    end

  end
end
