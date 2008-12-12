require 'find'
class PipelineController < ApplicationController

  # TODO: move some stuff into the private area so it can't be called by URL-hackers
  GD_COLORS = ['red', 'green', 'blue', 'white', 'black', 'orange', 'lightgrey', 'grey']
  STANZA_OPTIONS = {
    'fgcolor' => GD_COLORS,
    'bgcolor' => GD_COLORS,
    'group_on' => [ nil, 'sub { return shift->name }' ],
    'stranded' => [ 0, 1 ],
    'key' => :text,
    'label' => [ 'sub { return shift->name; }', 'sub { my ($type) = (shift->type =~ m/(.*):\d*/); return $type; }', 'sub { return eval { shift->{"attributes"}->{"load_id"}->[0]; } }', 'sub { return shift->source; }', 'sub { return eval { [ eval { shift->get_SeqFeatures; } ]->[0]->name }; }' ],
    'bump density' => :integer,
    'label density' => :integer,
    'glyph' => [
      'segments', 'arrow', 'anchored_arrow', 'box',
      'crossbox', 'dashed_line', 'diamond', 'dna', 'dot', 'dumbbell', 'ellipse' 'ex',
      'line', 'primers', 'saw_teeth', 'span', 'splice_site',
      'translation', 'triangle' 'two_bolts', 'wave', 'wiggle_density', 'wiggle_xyplot'
    ],
    'connector' => [ 'solid', 'dashed', 'none' ],
    'min_score' => :integer,
    'max_score' => :integer,
    'neg_color' => GD_COLORS,
    'pos_color' => GD_COLORS
  }

  before_filter :login_required, :except => [ :get_gbrowse_config ]
  before_filter :check_user_can_write, :except => 
        [
          :show,
          :new,
          :list,
          :status_table,
          :show_user,
	  :show_group,
          :deactivate_archive,
          :activate_archive,
          :command_status,
          :command_panel,
          :expand,
          :get_gbrowse_config
        ]

  before_filter :check_user_can_view, :except => 
        [
          :new,
          :list,
          :status_table,
          :show_user,
	  :show_group,
          :deactivate_archive,
          :activate_archive,
          :command_status,
          :expand ,
          :get_gbrowse_config
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
  
  def status_table
    begin
      @show_user = User.find(params[:user]) if params[:user]
    rescue
      @show_user = nil
      @show_group = nil
    end
    # Call main status renderer

    status

    render :partial => 'status_table'
  end

  def show_user
    user_to_view = (params[:user_id] && User.find(params[:user_id]) && current_user.is_a?(Moderator)) ? User.find(params[:user_id]) : current_user
    session[:show_filter_user] = user_to_view.id
    session[:show_filter] = :user
    status
    render :action => "status"
  end

  def show_group
    user_to_view = (params[:pi] && User.find_by_pi(params[:pi]) && current_user.is_a?(Moderator)) ? User.find_by_pi(params[:pi]) : current_user
    session[:show_filter_user] = user_to_view.id
    session[:show_filter] = :group
    status
    render :action => "status"
  end

  def list
    session[:show_filter] = nil
    status
    render :action => "status"
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
    @active_commands = @project.commands.all.find_all { |c| Command::Status::is_active_state(c.status) }.sort { |c1, c2| c1.queue_position <=> c2.queue_position }
    @active_command = @active_commands.find { |c| c.project_id = @project.id }
 
    render :partial => "command_panel"
  end

  def kill_command

    begin
      base_command = Command.find(params[:id])
    rescue
      flash[:error] = "CRAP Couldn't find command with ID #{params[:id]}"
      redirect_to :action => :list
      return false
    end
    @project = base_command.project

    unless (@project.nil? && current_user.is_a?(Administrator)) then
      return false unless check_user_can_view @project
    end

    base_command.destroy
    CommandController.running_flag = false
    CommandController.do_queued_commands
    @project.status = "(#{@project.status}) killed by Admin" 
    flash[:error] = "Admin illed command with ID #{params[:id]}"
    render reload
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

    @active_commands = @project.commands.all.find_all { |c| Command::Status::is_active_state(c.status) }.sort { |c1, c2| c1.queue_position <=> c2.queue_position }
    @active_command = @active_commands.find { |c| c.project_id = @project.id }

    @user_can_write = check_user_can_write @project, :skip_redirect => true
    @user_is_owner = check_user_is_owner @project

  end

  def download_chadoxml
    @autoRefresh = true
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    project_is_modencode = (@project.project_type == ProjectType.find_by_name("modENCODE Project"))
    unless project_is_modencode && Project::Status::ok_next_states(@project).include?(Project::Status::LOADING) then
      # Project hasn't yet gotten to the point where it can be loaded (no chadoxml generated)
      # OR project is not a modENCODE project and thus does not have a chadoXML associated
      flash[:error] = "Project does not have generated a ChadoXML file"
      redirect_to :action => "show", :id => @project
      return
    end
    chadoxmlfile = File.join(path_to_project_dir(@project), "extracted", "#{@project.id}.chadoxml")
    if File.exists? chadoxmlfile then
      send_file chadoxmlfile, :type => 'text/xml'
    else
      flash[:error] = "Project does not have generated a ChadoXML file"
      redirect_to :action => "show", :id => @project
    end
  end

  def expand_and_validate
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
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
    upcomment = params[:upload_comment]
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
      if params["skip_content_check"] == "yes" then
        extensions = extensionsByMIME.values.flatten.find_all { |ext| filename.ends_with?(".#{ext}") }
      end

      unless extensions 
        flash[:error] = "Invalid content_type=#{upfile.content_type.chomp}."
        @allow_skip_content_type = true
        return
      end

      unless extensions.any? {|ext| filename.ends_with?("." + ext) }
        flash[:error] = "File name <strong>#{filename}</strong> is invalid. " +
        "Only a compressed archive file (tar.gz, tar.bz2, zip) is allowed."
        return
      end
    end

    # Create a directory for putting the uploaded file into
    projectDir = File.dirname(path_to_file(filename))
    Dir.mkdir(projectDir,0775) unless File.exists?(projectDir)

    redirect_to :action => 'show', :id => @project

    # Upload in background
    do_upload(upurl, upftp, upfile, upcomment, filename, ftpFullPath)
 
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
    unless Project::Status::ok_next_states(@project).include?(Project::Status::LOADING) then
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

    unless Project::Status::ok_next_states(@project).include?(Project::Status::UNLOADING) then
#      flash[:error] = "Project status must be #{OKAY_TO_UNLOAD.orjoin}."
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
    unless Project::Status::ok_next_states(@project).include?(Project::Status::VALIDATING) then
#      flash[:error] = "Project status must be #{OKAY_TO_VALIDATE.orjoin}"
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
    unless Project::Status::ok_next_states(@project).include?(Project::Status::FINDING) then
#      flash[:error] = "Project status must be #{OKAY_TO_FIND_TRACKS.orjoin}"
      redirect_to :action => :show, :id => @project
      return false
    end

    do_find_tracks(@project)

    redirect_to :action => :show, :id => @project
  end

  def get_gbrowse_config
    begin
      @project = Project.find(params[:id])
    rescue
      render :text => "Couldn't find project with ID #{params[:id]}", :layout => false
      return
    end

    render :text => TrackFinder.new.generate_gbrowse_conf(@project.id), :layout => false
  end

  def configure_tracks
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    unless Project::Status::ok_next_states(@project).include?(Project::Status::CONFIGURING) then
#      flash[:error] = "Project status must be #{OKAY_TO_CONFIGURE_TRACKS.orjoin}"
      # Redirect here so that hitting refresh in the browser doesn't prompt annoyingly
      redirect_to :action => :show, :id => @project
      return false
    end

    if params[:delete_stanza] then
      if @project.status == Project::Status::CONFIGURED then
        @project.status = Project::Status::FOUND
        @project.save
      end

      # Unaccept config(s) for this project if any have been accepted
      TrackStanza.find_all_by_project_id(@project.id, current_user.id).each { |ts|
        ts.released = false
        ts.save
      }

      ts = TrackStanza.find_by_project_id_and_user_id(@project.id, current_user.id)
      ts.stanza = ts.stanza.reject { |key, value| key == params[:delete_stanza] }
      ts.save
      redirect_to :action => :configure_tracks, :id => @project
      return
    end
    
    if params[:accept_config] then
      @project.status = Project::Status::CONFIGURED
      @project.save

      # Unaccept config(s) for this project if any have been accepted
      TrackStanza.find_all_by_project_id(@project.id, current_user.id).each { |ts|
        ts.released = false
        ts.save
      }
      ts = TrackStanza.find_by_project_id_and_user_id(@project.id, current_user.id)
      ts.released = true
      ts.save
      redirect_to :action => :show, :id => @project
      return
    end


    released_ts = TrackStanza.find_by_project_id_and_released(@project.id, true)
    ts = nil
    if released_ts then
      ts = released_ts
      @released = true
    else
      ts = TrackStanza.find_by_project_id_and_user_id(@project.id, current_user.id)
      @released = false
    end
    if ts.nil? || params[:reset_definitions] then
      @track_defs = TrackFinder.new.generate_gbrowse_conf(@project.id)
      # Delete old one
      TrackStanza.destroy_all(:user_id => current_user.id, :project_id => @project.id) unless ts.nil?
      ts = TrackStanza.new :user_id => current_user.id, :project_id => @project.id, :marshaled_stanza => Marshal.dump(@track_defs)
      ts.save
      redirect_to :action => :configure_tracks, :id => @project
    else
      @ts_user = ts.user
      @track_defs = ts.stanza
    end

    @stanza_options = STANZA_OPTIONS
  end
      
  def async_update_track_location

    begin
      @project = Project.find(params[:id])
      if @project.status == Project::Status::CONFIGURED then
        @project.status = Project::Status::FOUND
        @project.save
      end
    rescue
    end

    # Unaccept config(s) for this project if any have been accepted
    TrackStanza.find_all_by_project_id(@project.id, current_user.id).each { |ts|
      ts.released = false
      ts.save
    }

    stanzaname = params[:stanzaname]
    changed = false
    user_stanzas = TrackStanza.find_all_by_user_id(current_user.id)
    user_stanza = user_stanzas.find { |ts| ts.stanza.has_key? stanzaname }

    stanzas = user_stanza.stanza
    if stanzas[stanzaname][:chr] != params[:chr] = params[:chr] then
      if params[:chr] =~ /^[a-zA-Z0-9_]+$/
        stanzas[stanzaname][:chr] = params[:chr] = params[:chr]
        changed = true
      end
    end
    if stanzas[stanzaname][:fmin] != params[:fmin] = params[:fmin] then
      if params[:fmin].to_s == params[:fmin].to_i.to_s
        stanzas[stanzaname][:fmin] = params[:fmin] = params[:fmin]
        changed = true
      end
    end
    if stanzas[stanzaname][:fmax] != params[:fmax] = params[:fmax] then
      if params[:fmax].to_s == params[:fmax].to_i.to_s
        stanzas[stanzaname][:fmax] = params[:fmax] = params[:fmax]
        changed = true
      end
    end

    # Update main track
    STANZA_OPTIONS.each do |option, values|
      value = params[option]
      if value then
        okay_value = false
        if values.is_a? Array then
          okay_value = true if values.member?(value)
        elsif values.is_a? Symbol then
          # Controlled type
          case values
          when :integer
            okay_value = true if value.to_i.to_s == value.to_s
          when :text
            okay_value = true if value =~ /^[a-zA-Z0-9_ -]*$/
          end
        end

        if okay_value then
          if (stanzas[stanzaname][option] != value) then
            stanzas[stanzaname][option] = value
            changed = true
          end
        end
      end
    end


    # Update semantic zoom tracks
    zoom_levels = params.keys.find_all { |key| key =~ /^zoom:\d+$/ }.map { |key| key[5..-1].to_i }

    zoom_levels.each do |zoom_level|
      next unless stanzas[stanzaname][:semantic_zoom] && stanzas[stanzaname][:semantic_zoom][zoom_level]
      STANZA_OPTIONS.each do |option, values|
        zoom_option = "zoom:#{zoom_level}_#{option}"
        value = params[zoom_option]
        if value then
          okay_value = false
          if values.is_a? Array then
            okay_value = true if values.member?(value)
          elsif values.is_a? Symbol then
            # Controlled type
            case values
            when :integer
              okay_value = true if value.to_i.to_s == value.to_s
            when :text
              okay_value = true if value =~ /^[a-zA-Z0-9_ -]*$/
            end
          end

          if okay_value then
            if (stanzas[stanzaname][:semantic_zoom][zoom_level][option] != value) then
              stanzas[stanzaname][:semantic_zoom][zoom_level][option] = value
              changed = true
            end
          end
        end
      end
      if params["zoom:#{zoom_level}"].to_i.to_s == params["zoom:#{zoom_level}"].to_s then
        new_zoom_level = params["zoom:#{zoom_level}"].to_i
        if new_zoom_level != zoom_level then
          # Trying to change the actual zoom_level
          stanzas[stanzaname][:semantic_zoom][new_zoom_level] = stanzas[stanzaname][:semantic_zoom][zoom_level]
          stanzas[stanzaname][:semantic_zoom].delete(zoom_level)

          # We should go ahead and force a refresh since this changes lots of underlying form fields
          headers["Content-Type"] = "application/javascript"
          render :text => "console.log('Zoom level being changed from #{zoom_level} to #{new_zoom_level}'); location.replace('#{url_for({ :action => :configure_tracks, :id => params[:id] })}')"
          return
        end
      end
    end


    # If anything changed
    if (changed) then

      user_stanza.stanza = stanzas
      user_stanza.save

      # Get the current location
      chr = stanzas[stanzaname][:chr]
      fmin = stanzas[stanzaname][:fmin]
      fmax = stanzas[stanzaname][:fmax]
      name = "#{chr}:#{fmin}..#{fmax}"

      # Update the track view with the new location
      headers["Content-Type"] = "application/javascript"
      render :text => "
        Controller.update_coordinates(
          '#{stanzaname}', 'name:#{name}', '#{chr}', #{fmin}, #{fmax}
        );
      "
      return
    end

    headers["Content-Type"] = "application/javascript"
    if params[:reload] then
      window.location.reload();
    else
      render :text => '1;'
    end
  end

  def full_command_history
    begin
      base_project = Project.find(params[:id])
      #base_command = Command.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => :list
      return false
      end
    @project = base_project

    unless (@project.nil? && current_user.is_a?(Administrator)) then
      return false unless check_user_can_view @project
    end
  end


  def release
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

    # Uploaded data?
    last_upload = (@project.commands.find_all_by_type('Upload::File')+@project.commands.find_all_by_type('Upload::Url')).sort { |a, b| a.id <=> b.id }.last
    @is_uploaded = {
      :done => Project::Status::ok_next_states(@project).include?(Project::Status::VALIDATING),
      :description => "Data Upload",
      :date => last_upload ? last_upload.updated_at : "never"
    }

    # Validated data?
    last_validation = @project.commands.find_all_by_type('ValidateIdf2chadoxml').sort { |a, b| a.id <=> b.id }.last
    @is_validated = {
      :done => Project::Status::ok_next_states(@project).include?(Project::Status::LOADING),
      :description => "Data Validated",
      :date => last_validation ? last_validation.updated_at : "never"
    }

    last_loading = @project.commands.find_all_by_type('LoadIdf2chadoxml').sort { |a, b| a.id <=> b.id }.last
    @is_loaded = {
      :done => Project::Status::ok_next_states(@project).include?(Project::Status::FINDING),
      :description => "Database loaded",
      :date => last_loading ? last_loading.updated_at : "never"
    }

    last_track_finding = @project.commands.find_all_by_type('FindTracks').sort { |a, b| a.id <=> b.id }.last
    @is_tracks_found = {
      :done => Project::Status::ok_next_states(@project).include?(Project::Status::CONFIGURING),
      :description => "Tracks found",
      :date => last_track_finding ? last_track_finding.updated_at : "never"
    }

    @is_tracks_configured = {
      :done => Project::Status::ok_next_states(@project).include?(Project::Status::AWAITING_RELEASE),
      :description => "Tracks configured",
      :date => (Project::Status::ok_next_states(@project).include?(Project::Status::AWAITING_RELEASE)) ? @project.updated_at : "never",
    }

    @checklist_for_data_validation = [@is_uploaded, @is_validated, @is_loaded, @is_tracks_found, @is_tracks_configured ]

    @checklist_for_release_by_pi = [ 
      [ "Submission files okay?", { :controller => :public, :action => :download, :id => @project } ],
      [ "GBrowse tracks okay?", { :action => :configure_tracks, :id => @project } ],
      [ "modMINE data okay?", {} ],
      [ "GEO submission okay?", {} ],
      # Worm/Flybase?
    ]

    @project_needs_release = @project.status == "released" ? false : true
    #    TODO
#    @project_ready_for_release = OKAY_TO_RELEASE_BY_PI.find { |s| s == @project.status } ? true : false
  end
  def project=(proj)
    @project = proj
  end

  def do_find_tracks(project, options = {})
    # Get the *Controller class to be used to do track finding
    TrackStanza.destroy_all "project_id = #{@project.id} AND user_id = #{current_user.id}"
    find_tracks_controller = FindTracksController.new(:project => project, :user_id => current_user.id)
    find_tracks_controller.queue options
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
  def do_upload(upurl, upftp, upfile, upcomment, filename, ftpFullPath)
    # TODO: Make this function private

    # Create a ProjectArchive to handle the upload
    (project_archive = @project.project_archives.new).save # So we get an archive_no
    project_archive.file_name = "#{"%03d" % project_archive.attributes[project_archive.position_column]}_#{filename}"
    project_archive.file_date = Time.now
    project_archive.is_active = false
    project_archive.comment = upcomment
    project_archive.save


    # Build a Command::Upload object to fetch the file
    if !upurl.blank? || upurl == "http://" then
      # Uploading from a remove URL; use open-uri (http://www.ruby-doc.org/stdlib/libdoc/open-uri/rdoc/)
      projectDir = path_to_project_dir(@project)

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

  def check_user_is_owner(project = nil)
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
    return project.user_id == current_user.id
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
      redirect_to :action => "list" unless options[:skip_redirect] == true 
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

  def path_to_project_dir(project = nil)
    project = @project if project.nil?
    # the expand_path method resolves this relative path to full absolute path
    File.expand_path("#{ActiveRecord::Base.configurations[RAILS_ENV]['upload']}/#{project.id}")
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

  def status

    user_to_view = session[:show_filter_user].nil? ? current_user : User.find(session[:show_filter_user])

    @viewing_user = user_to_view if user_to_view != current_user
    same_group_users = User.find_all_by_pi(user_to_view.pi)
    if session[:show_filter] == :user then
      @projects = user_to_view.projects
    elsif session[:show_filter] == :group then
      @projects = same_group_users.map { |u| u.projects }.flatten
    else  
      @projects = Project.all
    end

    session[:status_display_type] = params[:display_type] unless params[:display_type].nil?
    session[:status_display_date] = params[:display_date] unless params[:display_date].nil?
    session[:status_show_status] = params[:show_status] unless params[:show_status].nil?

    @display_type = session[:status_display_type] || 'compact'
    @display_date = session[:status_display_date] || 'quarter'
    @show_status = session[:status_show_status] || 'all'

    @projects = @projects.find_all{|p| p.status==Project::Status::RELEASED} if (session[:status_show_status] == 'released')
    @projects = @projects.find_all{|p| p.status!=Project::Status::RELEASED} if (session[:status_show_status] == 'active')


    if params[:sort] then
      session[:sort_list] = Hash.new unless session[:sort_list]
      params[:sort].each_pair { |column, direction| session[:sort_list][column] = [ direction, Time.now ] }
    end
    @new_sort_direction = Hash.new { |hash, column| hash[column] = 'forward' }
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
    else
      @projects = @projects.sort { |p1, p2| p1.name <=> p2.name }
    end

   @quarters = {"Y1Q3" => {"year" => "Y1", "quarter"=> "Q3", "start" => Date.civil(2007,11,1), "end" => Date.civil(2008,1,31)},
               "Y1Q4" => {"year" => "Y1", "quarter"=> "Q4", "start" => Date.civil(2008,2,1), "end" => Date.civil(2008,4,30)},
               "Y2Q1" => {"year" => "Y2", "quarter"=> "Q1", "start" => Date.civil(2008,5,1), "end" => Date.civil(2008,7,31)},
               "Y2Q2" => {"year" => "Y2", "quarter"=> "Q2", "start" => Date.civil(2008,8,1), "end" => Date.civil(2008,10,31) },
               "Y2Q3" => {"year" => "Y2", "quarter"=> "Q3", "start" => Date.civil(2008,11,1), "end" => Date.civil(2009,1,31) },
               "Y2Q4" => {"year" => "Y2", "quarter"=> "Q4", "start" => Date.civil(2009,2,1), "end" => Date.civil(2009,4,30) } }
    @status = ["New","Uploaded","Validated","DBLoad","Track Config","Aprvl-PI","Aprvl-DCC","to GBrowser","to Modmine","to WB/FB"]
    @active_status = @status[0..6]

    @all_projects_by_status = Hash.new {|status,count| status = count }
    @my_projects_by_status = Hash.new {|status,count| status = count }
    @my_groups_projects_by_status = Hash.new {|status,count| status = count }
    @my_active_projects_by_status = Hash.new {|status,count| status = count }
    @pis = Array.new

    @status.each {|s| @my_projects_by_status[s] = 0 }
    @status.each {|s| @my_groups_projects_by_status[s] = 0 }
    @status.each {|s| @all_projects_by_status[s] = 0 }
    @active_status.each {|s| @my_active_projects_by_status[s] = 0 }
    
    @projects.each do |p|
      step = 1
      #identify what step its at
      step = case p.status
             when Project::Status::NEW : 1
             when Upload::Status::UPLOAD_FAILED : 1
             when Upload::Status::UPLOADED : 2
             when Validate::Status::VALIDATION_FAILED : 2
             when Expand::Status::EXPAND_FAILED : 2
             when Validate::Status::VALIDATED : 3
             when Load::Status::LOAD_FAILED : 3
             when Load::Status::LOADED : 4
             when 'tracks found' : 5
             when 'submitter approval' : 6
             when 'DCC approval' : 7
             when 'released to gbrowse' : 8
             when 'released to modmine' : 9
             when 'released' : 10
             else 1
             end
      @pis.push p.user.pi
      @my_projects_by_status[@status[step-1]] += 1 unless p.user_id != user_to_view.id
      @my_groups_projects_by_status[@status[step-1]] += 1 unless !same_group_users.index(p.user_id).nil?
      @all_projects_by_status[@status[step-1]]+= 1
      if (step < @active_status.length)
        @my_active_projects_by_status[@active_status[step-1]] += 1
      end
    end

    @pis.uniq!

    @all_my_new_projects_per_quarter = Hash.new {|hash,quarter| hash[quarter] = 0 }
    # initialize to make sure all PIs are included; require each status to be represented
    @quarters.each{|k,v| @all_my_new_projects_per_quarter[k] = 0 unless v["start"] > Time.now.to_date}

    @projects.map{|p| @all_my_new_projects_per_quarter[@quarters.find{|k,v| p.created_at.to_date <= v["end"] && p.created_at.to_date >= v["start"]}[0]] += 1 }


    @all_my_released_projects_per_quarter = Hash.new {|hash,quarter| hash[quarter] = 0 }
    # initialize to make sure all PIs are included; require each status to be represented
    @quarters.each{|k,v| @all_my_released_projects_per_quarter[k] = 0 unless v["start"] > Time.now.to_date}

    @released_projects = @projects.find_all{|p| p.status=="released"}
    #for now, will use the last updated date, but should probably find the release command, and use that
    @released_projects.map{|p| @all_my_released_projects_per_quarter[@quarters.find{|k,v| p.updated_at.to_date <= v["end"] && p.created_at.to_date >= v["start"]}[0]] += 1 }



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
