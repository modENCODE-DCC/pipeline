require 'find'
class PublicController < ApplicationController
#  before_filter :download_check_user_can_view, :only => 
#  [
#    :get_gbrowse_stanzas,
#    :get_file,
#    :download,
#    :citation
#  ]


  def index
    redirect_to :action => :list
  end

  def list
    @projects = Project.all
#    # Anyone can view released projects or those in their group
#    if current_user.is_a?(Moderator) then
#      @projects = Project.all
#    else
#      @projects = Project.all.find_all { |p|
#        p.status == Project::Status::RELEASED || (current_user.is_a?(User) && p.user.pi == current_user.pi)
#      }
#    end


    @pis = User.all.map { |u| u.pi }.uniq
    @viewer_pi = current_user.is_a?(User) ? current_user.pi : nil
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
    if params[:pi] && params[:pi].length > 0 then
      @projects.reject! { |p| p.user.pi != params[:pi] }
    end
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

    all_track_defs = Array.new
    released_configs = TrackStanza.find_all_by_project_id_and_released(params[:id], true)
    unless current_user == :false then
      all_track_defs = TrackStanza.find_all_by_project_id(current_user, params[:id])
    end
    released_configs.each { |td|
      all_track_defs.delete_if { |atd| atd.project_id == td.project_id }
      all_track_defs.push td
    }

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
        next if value.nil?
        config_text << "#{option} = #{value.to_s.gsub("\n", "\n ")}\n"
      end
      config_text << "\n" if semantic_configs.size > 0
      semantic_configs.each do |zoom_level, zoom_definition|
        config_text << "[#{stanzaname}:#{zoom_level}]\n"
        zoom_definition.each do |option, value|
          next if option.is_a? Symbol
          next if value.nil?
          config_text << "#{option} = #{value.to_s.gsub("\n", "\n ")}\n"
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

  def citation
    config_text = ""

    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return false
    end

    all_track_defs = Array.new
    released_configs = TrackStanza.find_all_by_project_id_and_released(params[:id], true)
    unless current_user == :false then
      all_track_defs = TrackStanza.find_all_by_project_id(current_user, params[:id])
    end
    released_configs.each { |td|
      all_track_defs.delete_if { |atd| atd.project_id == td.project_id }
      all_track_defs.push td
    }

    track_defs = Hash.new
    all_track_defs.each { |td| track_defs.merge! td.stanza }

    @citations = Hash.new
    track_defs.each { |stanzaname, definition|
      tracknum = definition["feature"].match(/.*:(\d+)(_details)?$/)[1].to_i
      citation = definition["citation"]
      @citations[citation] = Array.new unless @citations[citation]
      @citations[citation].push [ stanzaname, tracknum ]
    }
  end

  def download
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    download_dir = ""
    download_dir = (params[:root] == "tracks") ? "tracks" : "extracted" if (params[:root] && params[:root].length > 0)
    @root = download_dir
    @root_directory = File.join(PipelineController.new.path_to_project_dir(@project), download_dir)

    unless File.directory?(@root_directory) then
      if @root.nil? || @root == "" then
        flash[:error] = "No data for this project."
        redirect_to :action => :list
      else
        flash[:warning] = "Data has not been extracted. Showing initial submission package."
        redirect_to :action => :download, :id => @project
      end
      return
    end

    @current_directory = params[:path] ? File.expand_path(File.join(@root_directory, params[:path])) : @root_directory

    unless File.directory?(@current_directory) then
      flash[:warning] = "No data found in: #{@current_directory}"
      @current_directory = @root_directory
      redirect_to :action => :list
    end
    unless @current_directory.index(@root_directory) == 0 then
      flash[:error] = "Invalid path"
      redirect_to :action => :download
    end

    if @current_directory != @root_directory then
      @parent = File.split(@current_directory)[0][@root_directory.length..-1]
    end

    @highlight = params[:highlight]

    @listing = Array.new
    Find.find(@current_directory) do |path|
      next if File.basename(path) == File.basename(@current_directory)
      relative_path = path[@root_directory.length..-1]
      if File.directory? path
        @listing.push [ :folder, relative_path, Array.new, 0 ]
        Find.prune
        next
      end
      size = File.size(path)
      if size.to_f >= (1024**2) then 
        size = "#{(size.to_f / 1024**2).round(1)}M"
      elsif size.to_f >= (1024) then
        size = "#{(size.to_f / 1024).round(1)}K"
      end
      @listing.push [ :file, relative_path, nil, size ]
    end
    @listing.sort! { |l1, l2| (l1[0] == :folder ? "0#{l1[1]}" : "1#{l1[1]}") <=> (l2[0] == :folder ? "0#{l2[1]}" : "1#{l2[1]}") }
    @listing.reject! { |l| !(l[1].include? @highlight) } if @highlight
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
    download_dir = ""
    download_dir = (params[:root] == "tracks") ? "tracks" : "extracted" if (params[:root] && params[:root].length > 0)
    @root_directory = File.join(PipelineController.new.path_to_project_dir(@project), download_dir)

    file = File.expand_path(File.join(@root_directory, params[:path]))

    unless file.index(@root_directory) == 0 then
      # Doesn't seem to be in the root directory
      flash[:error] = "Invalid path"
      redirect_to :action => :download
      return
    end
    unless File.file?(file) then
      flash[:error] = "Invalid path #{file}"
      redirect_to :action => :download, :id => params[:id], :root => params[:root] 
      return
    end

    send_file file, { :disposition => 'attachment', :filename => File.basename(file) }
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

    if (project.status == Project::Status::RELEASED) then
      return true
    elsif (current_user.is_a? User) then
      if current_user.is_a?(Reviewer) || project.user.pi == current_user.pi then
        return true
      end
      return false
    else
      redirect_to :action => "list"
      return false
    end
  end

end

