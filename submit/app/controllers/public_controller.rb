require 'find'
class PublicController < ApplicationController
  before_filter :download_check_user_can_view, :only => 
  [
    :get_gbrowse_stanzas,
    :get_file,
    :download
  ]


  def index
    redirect_to :controller => :pipeline, :action => :index
  end

  def list
    # Anyone can view released projects or those in their group
    if current_user.is_a?(Moderator) then
      @projects = Project.all
    else
      @projects = Project.all.find_all { |p|
        p.status == Project::Status::RELEASED || p.user.pi == current_user.pi
      }
    end

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

  end

  def get_gbrowse_stanzas
    config_text = ""

    begin
      project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return false
    end

    all_track_defs = TrackStanza.find_all_by_user_id_and_project_id(current_user, params[:id])
    track_defs = Hash.new
    all_track_defs.each { |td| track_defs.merge! td.stanza }

    track_defs.map { |stanzaname, definition| definition['database'] }.uniq.each do |database|
      num = database.gsub(/^modencode_preview_/, '')
      config_text << "[#{database}:database]\n"
      config_text << "db_adaptor    = Bio::DB::SeqFeature::Store\n"
      config_text << "db_args       = -adaptor DBI::Pg\n"
      config_text << "                -dsn     dbname=modencode_gffdb;host=localhost\n"
      config_text << "                -user    '????????'\n"
      config_text << "                -pass    '????????'\n"
      config_text << "\n"
    end

    track_defs.each do |stanzaname, definition|
      semantic_configs = definition[:semantic_zoom]

      config_text << "[#{stanzaname}]\n"
      definition.each do |option, value|
        next if option.is_a? Symbol
        config_text << "#{option} = #{value}\n"
      end
      config_text << "\n" if semantic_configs.size > 0
      semantic_configs.each do |zoom_level, zoom_definition|
        config_text << "[#{stanzaname}:#{zoom_level}]\n"
        zoom_definition.each do |option, value|
          config_text << "#{option} = #{value}\n"
        end
      end
      config_text << "\n\n\n"
    end
    if config_text.length > 0 then
      config_text = "# GBrowse stanza configuration for tracks generated\n# for project ##{project.id}: #{project.name}\n\n" + config_text
      send_data config_text, :type => "text/plain", :filename => "stanzas.txt", :disposition => "inline"
    else
      render :text => "No tracks configured for this project."
    end
  end

  def download
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "index"
      return
    end
    # TODO: Make sure that this project is actually released
    download_dir = (params[:root] == "tracks") ? "tracks" : "extracted"
    @root_directory = File.join(PipelineController.new.path_to_project_dir(@project), download_dir)

    unless File.directory?(@root_directory) then
      redirect_to :action => :list
    end

    @current_directory = params[:path] ? File.expand_path(File.join(@root_directory, params[:path])) : @root_directory

    unless File.directory?(@current_directory) then
      flash[:warning] = "Invalid path: #{@current_directory}"
      @current_directory = @root_directory
    end
    unless @current_directory.index(@root_directory) == 0 then
      flash[:error] = "Invalid path"
      redirect_to :action => :download
    end

    if @current_directory != @root_directory then
      @parent = File.split(@current_directory)[0][@root_directory.length..-1]
    end


    @listing = Array.new
    Find.find(@current_directory) do |path|
      next if File.basename(path) == File.basename(@current_directory)
      relative_path = path[@root_directory.length..-1]
      if File.directory? path
        @listing.push [relative_path, Array.new]
        Find.prune
        next
      end
      @listing.push relative_path
    end
  end

  def get_file
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "download"
      return
    end
    # TODO: Make sure that this project is actually released
    download_dir = (params[:root] == "tracks") ? "tracks" : "extracted"
    @root_directory = File.join(PipelineController.new.path_to_project_dir(@project), download_dir)

    file = File.expand_path(File.join(@root_directory, params[:path]))

    unless file.index(@root_directory) == 0 then
      # Doesn't seem to be in the root directory
      flash[:error] = "Invalid path"
      redirect_to :action => :download
      return
    end
    unless File.file?(file) then
      flash[:error] = "Invalid path"
      redirect_to :action => :download
      return
    end

    send_file file
  end

  private
  def download_check_user_can_view
    project = nil
    begin
      project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return false
    end

    if current_user.is_a?(Reviewer) || project.status == Project::Status::RELEASED || project.user.pi == current_user.pi then
      return true
    else
      redirect_to :action => "list"
      return false
    end
  end

end

