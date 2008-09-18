require 'find'
class PipelineController < ApplicationController

  # TODO: move some stuff into the private area so it can't be called by URL-hackers

  OKAY_TO_VALIDATE = [
    Expand::Status::EXPANDED,
    Upload::Status::UPLOADED,
    Validate::Status::VALIDATED,
    Validate::Status::VALIDATION_FAILED,
    Load::Status::LOADED,
    Load::Status::LOAD_FAILED,
    Unload::Status::UNLOADED,
    Unload::Status::UNLOAD_FAILED
  ]
  OKAY_TO_EXPAND = [
    Expand::Status::EXPANDED,
    Expand::Status::EXPAND_FAILED,
    Upload::Status::UPLOADED,
    Validate::Status::VALIDATED,
    Validate::Status::VALIDATION_FAILED,
    Load::Status::LOADED,
    Load::Status::LOAD_FAILED,
    Unload::Status::UNLOADED,
    Unload::Status::UNLOAD_FAILED
  ]
  OKAY_TO_LOAD = [
    Validate::Status::VALIDATED,
    Load::Status::LOADED,
    Load::Status::LOAD_FAILED,
    Unload::Status::UNLOADED,
    Unload::Status::UNLOAD_FAILED
  ]
  OKAY_TO_UNLOAD = [
    Load::Status::LOADED,
    Unload::Status::UNLOAD_FAILED
  ]
  OKAY_TO_PROCESS = [
    Load::Status::LOADED
  ]
  [ OKAY_TO_VALIDATE, OKAY_TO_EXPAND, OKAY_TO_LOAD, OKAY_TO_UNLOAD, OKAY_TO_PROCESS ].each { |c|
    def c.orjoin(delim = ", ", lastjoin = "or")
      if self.size > 2 then
        return "#{self[0...-1].join(delim)}#{delim}#{lastjoin} #{self[-1]}"
      elsif self.size > 1 then
        return self.join(" #{lastjoin} ")
      else
        return self.join(delim)
      end
    end
  }

  before_filter :login_required
  before_filter :check_user_can_write, :except => 
        [
          :show,
          :new,
          :list,
          :show_user,
          :deactivate_archive,
          :activate_archive,
          :command_status,
          :command_panel,
          :expand 
        ]

  before_filter :check_user_can_view, :except => 
        [
          :new,
          :list,
          :show_user,
          :deactivate_archive,
          :activate_archive,
          :command_status,
          :expand 
        ]

  def edit
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    @projectTypes = getProjectTypes

    if params[:commit] then
      old_project_type_id = @project.project_type_id
      if @project.update_attributes(params[:project]) then
        redirect_to :action => 'show', :id => @project
      else
        flash[:error] = "Couldn't save project #{$!}."
      end
    end
  end
  
  def list

    @autoRefresh = true
    @projects = Project.find(:all)#, :order => 'name')


    if params[:sort] then
      session[:sort_list] = Hash.new unless session[:sort_list]
      params[:sort].each_pair { |column, direction| session[:sort_list][column] = [ direction, Time.now ] }
    end
    @new_sort_direction = Hash.new { |hash, column| hash[column] = 'forward' }
    if session[:sort_list] then
      sorts = session[:sort_list].sort_by { |column, sortby| sortby[1] }.reverse.map { |column, sortby| column }
      @projects = @projects.sort { |p1, p2|
        p1_attrs = sorts.map { |col| (session[:sort_list][col][0] == 'backward') ?  p2.attributes[col] : p1.attributes[col] } << p1.id
        p2_attrs = sorts.map { |col| (session[:sort_list][col][0] == 'backward') ?  p1.attributes[col] : p2.attributes[col] } << p2.id
        p1_attrs <=> p2_attrs
      }
      session[:sort_list].each_pair { |col, srtby| @new_sort_direction[col] = 'backward' if srtby[0] == 'forward' && sorts[0] == col }
    end

  end
  
  def command_panel
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    @last_command_run = @project.commands.find_all { |cmd| cmd.status != Command::Status::QUEUED }.last

    render :partial => "command_panel"
  end

  def command_status

    begin
      base_command = Command.find(params[:id])
    rescue
      flash[:error] = "Couldn't find command with ID #{params[:id]}"
      redirect_to :action => :list
      return false
    end
    @project = base_command.project

    unless (@project.nil? && current_user.is_a?(Administrator)) then
      return false unless check_user_can_view @project
    end

    begin
      command_type = base_command.class_name.singularize.camelize.constantize
    rescue
      command_type = Command
    end

    @command = command_type.find(params[:id])
    render :action => "command_status", :layout => "popup"
  end

  def new
    if params[:commit] == "Cancel"
      redirect_to :action => 'show_user'
      return
    end
    if (params[:project]) then
      @project = Project.new(params[:project])
    else
      @project = Project.new
    end
    @projectTypes = getProjectTypes

    if params[:commit] then
      @project.user_id = current_user.id 
      @project.status = Project::Status::NEW
      if @project.save
        redirect_to :action => 'upload', :id => @project.id
        log_project_status
      end
    end
    #render :action => Project::Status::NEW
  end
  
  def show
    @autoRefresh = true
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

    @last_command_run = @project.commands.find_all { |cmd| cmd.status != Command::Status::QUEUED }.last
    @num_active_archives = @project.project_archives.find_all { |pa| pa.is_active }.size
    @num_archives = @project.project_archives.size

    @project_can_validate = (@num_active_archives > 0 && OKAY_TO_VALIDATE.find { |s| s == @project.status }) ? true : false
    @project_needs_expansion = (
      (
        # Archives are active but not expanded
        @project.project_archives.find_all { |pa| pa.is_active && pa.status != Expand::Status::EXPANDED }.size > 0 ||
        # Need to re-expand after failed validation
        @project.status == Validate::Status::VALIDATION_FAILED
      ) && (
        OKAY_TO_EXPAND.find { |s| s == @project.status }
      )
    ) ? true : false

    @project_can_load = (OKAY_TO_LOAD.find { |s| s == @project.status }) && (@project.project_archives.size > 0) ? true : false
    @project_can_unload = OKAY_TO_UNLOAD.find { |s| s == @project.status } ? true : false
    @project_can_expand = (OKAY_TO_EXPAND.find { |s| s == @project.status }) && (@project.project_archives.size > 0) ? true : false
    @project_can_process = OKAY_TO_PROCESS.find { |s| s == @project.status } ? true : false
    @user_can_write = check_user_can_write @project, :skip_redirect => true
  end

  def expand_and_validate
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

    if @project.status == Expand::Status::EXPANDING then
      flash[:error] = "Already expanding an archive, please wait until that process is complete."
      redirect_to :action => "show", :id => @project
      return
    end

    # ---------EXPAND ALL--------------
    # Delete everything in the extracted dir since it's no longer up-to-date
    ExpandController.remove_extracted_folder(@project.project_archives.first)

    # Rexpand any active archives from oldest to newest
    current_project_archive = @project.project_archives.first
    while (current_project_archive)
      do_expand(current_project_archive, :defer => true) if current_project_archive.is_active
      current_project_archive = current_project_archive.lower_item
    end

    # ---------VALIDATE--------------
    do_validate(@project) # Don't defer; we'll start processing

    redirect_to :action => :show, :id => @project
  end

  def expand_all
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

    if @project.status == Expand::Status::EXPANDING then
      flash[:error] = "Already expanding an archive, please wait until that process is complete."
      redirect_to :action => "show", :id => @project
      return
    end

    # Expand this archive in the background
    @project.status = Expand::Status::EXPANDING
    @project.save
    
    # Clean up any expanded archives
    @project.project_archives.each do |pa| 
      pa.status = ProjectArchive::Status::NOT_EXPANDED
      pa.save
      pa.project_files.each do |pf|
        pf.destroy
      end
    end
    # Also need to delete everything in the extracted dir since it's no longer up-to-date
    ExpandController.remove_extracted_folder(@project.project_archives.first)

    # Rexpand any active archives from oldest to newest
    current_project_archive = @project.project_archives.first
    while (current_project_archive)
      do_expand(current_project_archive, :defer => true) if current_project_archive.is_active
      current_project_archive = current_project_archive.lower_item
    end

    CommandController.do_queued_commands

    redirect_to :action => 'show', :id => @project
  end

  def expand
    begin
      project_archive = ProjectArchive.find(params[:id])
      @project = project_archive.project
      return false unless check_user_can_write @project
    rescue
      flash[:error] = "Couldn't find project archive with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

    if project_archive.project.status == Expand::Status::EXPANDING then
      flash[:error] = "Already expanding an archive, please wait until that process is complete."
      redirect_to :action => "show", :id => @project
      return
    end

    project_archive.project.project_archives.find_all do |pa| 
      if pa != project_archive then
        do_deactivate_archive(pa)
      end
    end
    do_activate_archive(project_archive)

    # Expand this archive in the background
    project_archive.project.status = Expand::Status::EXPANDING
    project_archive.project.save

    # Clean up any expanded archives
    @project.project_archives.each do |pa| 
      pa.status = ProjectArchive::Status::NOT_EXPANDED
      pa.save
      pa.project_files.each do |pf|
        pf.destroy
      end
    end

    # Also need to delete everything in the extracted dir since it's no longer up-to-date
    ExpandController.remove_extracted_folder(project_archive)

    # Rexpand any active archives prior to this one
    do_expand(project_archive)

    redirect_to :action => 'show', :id => @project
  end

  def upload
    @project = Project.find(params[:id])
    @user = current_user

    extensions = ["zip", "ZIP", "tar.gz", "TAR.GZ", "tar.bz2", "TAR.BZ2", "tgz", "TGZ"]

    # handle FTP stuff
    @use_ftp = (ActiveRecord::Base.configurations[RAILS_ENV]['ftpServer'].nil? ? false : true)
    if @use_ftp then
      @ftpList = []
      @ftpUrl = "ftp://#{@user.login}@#{ActiveRecord::Base.configurations[RAILS_ENV]['ftpServer']}"+
             ":#{ActiveRecord::Base.configurations[RAILS_ENV]['ftpPort']}"
      ftpFullPath = ActiveRecord::Base.configurations[RAILS_ENV]['ftpMount']+'/'+@user.login
      if File.exists?(ftpFullPath)
        Dir.entries(ftpFullPath).each do
          |file|
          fullName = File.join(ftpFullPath,file)
          if File.ftype(fullName) == "file"
            if extensions.any? {|ext| file.ends_with?("." + ext) }
              @ftpList << file
            end
          end
        end
      end
    end

    return unless request.post?

    # Handle form posts
    # If Cancel was clicked, return to main project page
    if params[:commit] == "Cancel"
      redirect_to :action => 'show', :id => @project
      return
    end

    # If submitted by another button, then it was an attempted upload
    upurl = params[:upload_url]
    upfile = params[:upload_file]
    upftp = params[:ftp]
    upurl = "" if upurl.nil? or upurl == "http://" # If it's the default value, ignore it
    upftp = "" unless upftp # Don't let upftp be nil

    # If nothing was submitted, return
    if upfile.blank? && upurl.blank? && upftp.blank? then
      flash[:warning] = "No file submitted. Please upload a file to continue."
      return 
    end

    # Get the filename of the file being uploaded
    if !upurl.blank? then
      # Use a URL
      filename = sanitize_filename(upurl)
    elsif !upftp.blank? then
      # Use a file uploaded from FTP
      filename = sanitize_filename(upftp)
    else # !upfile.blank?
      # Use a file uploaded through the browser
      filename = sanitize_filename(upfile.original_filename)
      extensionsByMIME = {
          "application/zip" => ["zip", "ZIP"],
          "application/x-tar" => ["tar.gz", "TAR.GZ", "tar.bz2", "TAR.BZ2", "tgz", "TGZ"],
          "application/x-compressed-tar" => ["tar.gz", "TAR.GZ", "tar.bz2", "TAR.BZ2", "tgz", "TGZ"],
          "application/octet-stream" => ["tar.gz", "TAR.GZ", "tar.bz2", "TAR.BZ2", "tgz", "TGZ"],
          "application/gzip" => ["tar.gz", "TAR.GZ", "tgz", "TGZ"],
          "application/x-gzip" => ["tar.gz", "TAR.GZ", "tgz", "TGZ"]
      }
      extensions = extensionsByMIME[upfile.content_type.chomp]
      unless extensions
        flash[:error] = "Invalid content_type=#{upfile.content_type.chomp}."
        return
      end
    end

    unless extensions.any? {|ext| filename.ends_with?("." + ext) }
      flash[:error] = "File name <strong>#{filename}</strong> is invalid. " +
        "Only a compressed archive file (tar.gz, tar.bz2, zip) is allowed."
      return
    end

    # Create a directory for putting the uploaded file into
    projectDir = File.dirname(path_to_file(filename))
    Dir.mkdir(projectDir,0775) unless File.exists?(projectDir)

    flash[:notice] = "Uploading #{filename}.<br>"

    redirect_to :action => 'show', :id => @project

    # Upload in background
    do_upload(upurl, upftp, upfile, filename, ftpFullPath)
 
  end

  def show_user

    @autoRefresh = true
    @user = User.find(current_user.id)
    @projects = @user.projects


    if params[:sort] then
      session[:sort_list] = Hash.new unless session[:sort_list]
      params[:sort].each_pair { |column, direction| session[:sort_list][column] = [ direction, Time.now ] }
    end
    @new_sort_direction = Hash.new { |hash, column| hash[column] = 'forward' }
    if session[:sort_list] then
      sorts = session[:sort_list].sort_by { |column, sortby| sortby[1] }.reverse.map { |column, sortby| column }
      @projects = @projects.sort { |p1, p2|
        p1_attrs = sorts.map { |col| (session[:sort_list][col][0] == 'backward') ?  p2.attributes[col] : p1.attributes[col] } << p1.id
        p2_attrs = sorts.map { |col| (session[:sort_list][col][0] == 'backward') ?  p1.attributes[col] : p2.attributes[col] } << p2.id
        p1_attrs <=> p2_attrs
      }
      session[:sort_list].each_pair { |col, srtby| @new_sort_direction[col] = 'backward' if srtby[0] == 'forward' && sorts[0] == col }
    end


    render :action => 'list'
    
  end
  
  def begin_loading
    # TODO: Delete this function
    @project = Project.find(params[:id])
    if @project.status == Validate::Status::VALIDATED
      @project.status = Load::Status::LOADING
      @project.save
      log_project_status
    end
    redirect_to :action => 'show', :id => @project.id
    galtDebug = false  # set to true to cause processing in parent without child 
                       # for debugging so you can see the error messages
    if galtDebug
      load
    else
      # TODO: Used to fork
        load 
    end
  end

  def deactivate_archive
    project_archive = ProjectArchive.find(params[:id])
    @project = project_archive.project
    return false unless check_user_can_write @project

    do_deactivate_archive(project_archive)
    redirect_to :action => 'show', :id => @project
  end

  def activate_archive
    project_archive = ProjectArchive.find(params[:id])
    @project = project_archive.project
    return false unless check_user_can_write @project

    do_activate_archive(project_archive)
    redirect_to :action => 'show', :id => @project
  end

  def activate_all
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

      @project.project_archives.each do |project_archive|
        do_activate_archive(project_archive)
      end

    redirect_to :action => 'show', :id => @project
  end

  def deactivate_all
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

      @project.project_archives.each do |project_archive|
        do_deactivate_archive(project_archive)
      end

    redirect_to :action => 'show', :id => @project
  end

  def _load
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

    unless @project.project_archives.find_all { |pa| pa.is_active }.size > 0 then
      flash[:error] = "At least one archive must be active."
      redirect_to :action => :show, :id => @project
      return false
    end
    unless OKAY_TO_LOAD.find { |s| s == @project.status } then
      flash[:error] = "Project status must be #{OKAY_TO_LOAD.orjoin}."
      redirect_to :action => :show, :id => @project
      return false
    end
    if @project.project_archives.find_all { |pa| pa.is_active && pa.status != ProjectArchive::Status::EXPANDED }.size > 0 then
      flash[:error] = "All active archives must be expanded."
      redirect_to :action => :show, :id => @project
      return false
    end

    do_load(@project)

    redirect_to :action => :show, :id => @project
  end 

  def unload
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

    unless OKAY_TO_UNLOAD.find { |s| s == @project.status } then
      flash[:error] = "Project status must be #{OKAY_TO_UNLOAD.orjoin}."
      redirect_to :action => :show, :id => @project
      return false
    end

    do_unload(@project)

    redirect_to :action => :show, :id => @project
  end 

  def delete
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

    # TODO: Stop all running tasks

    # Queue up unload and delete tasks
    do_unload(@project, :defer => true)
    do_delete(@project)

    redirect_to :action => :list
  end

  def do_delete(project, options = {})
    # TODO: Make this function private

    delete_controller = DeleteController.new(:project => project)

    delete_controller.queue options
  end

  def validate
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

    unless @project.project_archives.find_all { |pa| pa.is_active }.size > 0 then
      flash[:error] = "At least one archive must be active."
      redirect_to :action => :show, :id => @project
      return false
    end
    unless OKAY_TO_VALIDATE.find { |s| s == @project.status } then
      flash[:error] = "Project status must be #{OKAY_TO_VALIDATE.orjoin}"
      redirect_to :action => :show, :id => @project
      return false
    end
    if @project.project_archives.find_all { |pa| pa.is_active && pa.status != ProjectArchive::Status::EXPANDED }.size > 0 then
      flash[:error] = "All active archives must be expanded."
      redirect_to :action => :show, :id => @project
      return false
    end

    do_validate(@project)

    redirect_to :action => :show, :id => @project
  end 

  def find_tracks
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    unless OKAY_TO_PROCESS.find { |s| s == @project.status } then
      flash[:error] = "Project status must be #{OKAY_TO_PROCESS.orjoin}"
      redirect_to :action => :show, :id => @project
      return false
    end

    do_find_tracks(@project)

    redirect_to :action => :show, :id => @project
  end

#private # --------- PRIVATE ---------
  def project=(proj)
    @project = proj
  end

  def do_find_tracks(project, options = {})
  end

  def do_load(project, options = {})
    # Get the *Controller class to be used to do loading
    begin
      load_class = getProjectType(project).load_wrapper_class.singularize.camelize.constantize
    rescue
      load_class = Load
    end

    if load_class.ancestors.map { |a| a.name == 'CommandController' }.find { |a| a } then
      load_controller_class = load_class
    else
      # Command.is_a? Command
      if load_class.ancestors.map { |a| a.name == 'Command' }.find { |a| a } then
        begin
          load_controller_class = (load_class.name + "Controller").camelize.constantize
        rescue
          load_controller_class = LoadController
        end
      else
        throw :expecting_subclass_of_command_or_command_controller
      end
    end

    load_controller = load_controller_class.new(:project => project)
    load_controller.queue options
  end

  def do_unload(project, options = {})
    # Get the *Controller class to be used to do unloading
    begin
      unload_class = getProjectType(project).unload_wrapper_class.singularize.camelize.constantize
    rescue
      unload_class = Unload
    end

    if unload_class.ancestors.map { |a| a.name == 'CommandController' }.find { |a| a } then
      unload_controller_class = unload_class
    else
      # Command.is_a? Command
      if unload_class.ancestors.map { |a| a.name == 'Command' }.find { |a| a } then
        begin
          unload_controller_class = (unload_class.name + "Controller").camelize.constantize
        rescue
          unload_controller_class = UnloadController
        end
      else
        throw :expecting_subclass_of_command_or_command_controller
      end
    end

    unload_controller = unload_controller_class.new(:project => project)
    unload_controller.queue options
  end

  def do_validate(project, options = {})
    # Get the *Controller class to be used to do validation
    begin
      validate_class = getProjectType(project).validate_wrapper_class.singularize.camelize.constantize
    rescue
      validate_class = Validate
    end

    if validate_class.ancestors.map { |a| a.name == 'CommandController' }.find { |a| a } then
      validate_controller_class = validate_class
    else
      # Command.is_a? Command
      if validate_class.ancestors.map { |a| a.name == 'Command' }.find { |a| a } then
        begin
          validate_controller_class = (validate_class.name + "Controller").camelize.constantize
        rescue
          validate_controller_class = ValidateController
        end
      else
        throw :expecting_subclass_of_command_or_command_controller
      end
    end

    validate_controller = validate_controller_class.new(:project => project)
    validate_controller.queue options

  end
  def do_activate_archive(project_archive)
    # TODO: Make this function private
    return unless project_archive.file_size.to_i > 0
    
    project_archive.is_active = true
    project_archive.save

    @project.project_archives.each do |pa| 
      pa.status = ProjectArchive::Status::NOT_EXPANDED
      pa.save
      pa.project_files.each do |pf|
        pf.destroy
      end
    end
    # Also need to delete everything in the extracted dir since it's no longer up-to-date
    ExpandController.remove_extracted_folder(project_archive)
  end

  def do_deactivate_archive(project_archive)
    # TODO: Make this function private
    # Don't delete, just mark as inactive and clean out expanded archives
    project_archive.is_active = false
    project_archive.save

    @project.project_archives.each do |pa| 
      pa.status = ProjectArchive::Status::NOT_EXPANDED
      pa.save
      pa.project_files.each do |pf|
        pf.destroy
      end
    end
    # Also need to delete everything in the extracted dir since it's no longer up-to-date
    ExpandController.remove_extracted_folder(project_archive)
  end

  def do_expand(project_archive, options = {})
    return unless project_archive.file_size.to_i > 0
    project_archive.is_active = true
    project_archive.save
    expand_controller = ExpandController.new(:filename => project_archive.file_name, :project => project_archive.project)

    expand_controller.queue options
  end
  def do_upload(upurl, upftp, upfile, filename, ftpFullPath)
    # TODO: Make this function private

    # Create a ProjectArchive to handle the upload
    (project_archive = @project.project_archives.new).save # So we get an archive_no
    project_archive.file_name = "#{"%03d" % project_archive.attributes[project_archive.position_column]}_#{filename}"
    project_archive.file_date = Time.now
    project_archive.is_active = false
    project_archive.save


    # Build a Command::Upload object to fetch the file
    if !upurl.blank? || upurl == "http://" then
      # Uploading from a remove URL; use open-uri (http://www.ruby-doc.org/stdlib/libdoc/open-uri/rdoc/)
      projectDir = path_to_project_dir

      upload_controller = UrlUploadController.new(:source => upurl, :filename => path_to_file(project_archive.file_name), :project => @project)
      upload_controller.timeout = 36000 # 10 hours

      # Queue upload command
      upload_controller.queue
    elsif !upftp.blank?
      # Uploading from the FTP site
      FileUtils.copy(File.join(ftpFullPath,upftp), path_to_file(project_archive.file_name))
      upload_controller = FileUploadController.new(:source => File.join(ftpFullPath,upftp), :filename => path_to_file(project_archive.file_name), :project => @project) 
      upload_controller.timeout = 600 # 10 minutes

      # Queue upload command
      upload_controller.queue
    else
      # Uploading from the browser
      if !upfile.local_path
        # TODO: Need an uploader here
        File.open(path_to_file(project_archive.file_name), "wb") { |f| f.write(upfile.read) }
        upload_controller = FileUploadController.new(:source => path_to_file(project_archive.file_name), :filename => path_to_file(project_archive.file_name), :project => @project)
        upload_controller.timeout = 20 # 20 seconds
      else
        upload_controller = FileUploadController.new(:source => upfile.local_path, :filename => path_to_file(project_archive.file_name), :project => @project)
        upload_controller.timeout = 600 # 10 minutes
      end

      # Immediately run upload command
      # (Since this was uploaded from a browser, need to copy the file before the tmp file dissapears)
      upload_controller.run
    end

  end

  def check_user_can_write(project = nil, options = {})
    begin
      if project.nil? then
        project = Project.find(params[:id])
      elsif project.is_a? Fixnum
        project = Project.find(project)
      end
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    unless project.user_id == current_user.id || current_user.is_a?(Administrator) || current_user.is_a?(Moderator)
      flash[:error] = "This project does not belong to you." unless options[:skip_redirect] == true 
      redirect_to :action => 'show', :id => project unless options[:skip_redirect] == true 
      return false
    end
    if project.user_id != current_user.id then
      flash[:warning] = "Note: This project (#{project.name}) does not belong to you, but you are allowed to make changes." unless options[:skip_redirect] == true 
      flash.discard(:warning)
    end
    return true
  end

  def check_user_can_view(project = nil, options = {})
    begin
      if project.nil? then
        project = Project.find(params[:id])
      elsif project.is_a? Fixnum
        project = Project.find(project)
      end
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    unless project.user_id == current_user.id || current_user.is_a?(Administrator) || current_user.is_a?(Moderator) || current_user.is_a?(Reviewer)
      flash[:error] = "That project does not belong to you." unless options[:skip_redirect] == true 
      redirect_to :action => 'list' unless options[:skip_redirect] == true 
      return false
    end
    return true
  end

  # --- file upload routines ---
  def sanitize_filename(file_name)
    # get only the filename, not the whole path (from IE)
    just_filename = File.basename(file_name) 
    # replace all non-alphanumeric, underscore or periods with underscore
    just_filename.gsub(/[^\w\.\_]/,'_') 
  end

  def path_to_project_dir
    # the expand_path method resolves this relative path to full absolute path
    File.expand_path("#{ActiveRecord::Base.configurations[RAILS_ENV]['upload']}/#{@project.id}")
  end

  def path_to_file(filename)
    # the expand_path method resolves this relative path to full absolute path
    path_to_project_dir+"/#{filename}"
  end

  def getProjectTypes
    # --- read project types from config file into hash -------
    #open("#{RAILS_ROOT}/config/projectTypes.yml") { |f| YAML.load(f.read) }
    types = ProjectType.find(:all, :conditions => ['display_order != 0'], :order => "display_order")
    unless types.size > 0 then
      flash[:warning] = "Can't load project types, attemping to load config/projectTypes.yml"
      if File.exists? "#{RAILS_ROOT}/config/projectTypes.yml" then
          open("#{RAILS_ROOT}/config/projectTypes.yml") { |f| YAML.load(f.read) }.each_pair { |name, definition|
              pt = ProjectType.new(definition)
              pt.save
              if (pt.errors.size > 0) then
                flash[:warning] += "<br/>Couldn't process ProjectType definition in projectTypes.yml from #{name}"
                flash[:warning] += "<br/><ul>" + pt.errors.map { |attrib, msg| "<li>#{attrib} #{msg}</li>" }.join("\n") + "</ul>"
              else
                types += [pt]
              end
          }
      end
    end
    unless types.size > 0 then
      flash[:error] += "<br/>Can't load any project types, please populate projectTypes.yml"
    end
    return types
  end

  def getProjectType(project)
    # --- read one project type from config file into hash -------
    projectTypes = getProjectTypes
    projectTypes.each do |x|
      if x['id'] == project.project_type_id
        return x
      end
    end
  end

  def run_with_timeout(cmd, myTimeout)
    # --- run process with timeout ---- (probably should move this to an application helper location)
    # run process, kill it if exceeds specified timeout in seconds
    sleepInterval = 0.5  #seconds
    if ( (cpid = fork) == nil)
      exec(cmd)
    else
      before = Time.now
      while (true)
	pid, status = Process.wait2(cpid,Process::WNOHANG)
        if pid == cpid
          return status.exitstatus
        end
        if ( (Time.now - before) > myTimeout)
          Process.kill("ABRT",cpid)
	  pid, status = Process.wait2(cpid) # clean up zombies
          return -1
        end
        sleep(sleepInterval)
      end
    end
  end

  def log_project_status
    # add new projectArchive record
    project_status_log = ProjectStatusLog.new
    project_status_log.project_id = @project.id 
    project_status_log.status = @project.status
    unless project_status_log.save
      flash[:error] = "System error saving project_status_log record."
    end
  end
 
end
