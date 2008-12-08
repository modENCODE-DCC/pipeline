require 'find'
class PublicController < ApplicationController
  before_filter :login_required

  def index
    @projects = Project.all
    @released_projects = Project.find_all_by_status(Project::Status::RELEASED)
    @projects = Project.find(:all)#, :order => 'name')

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
    end

   @quarters = {"Y1Q3" => {"year" => "Y1", "quarter"=> "Q3", "start" => Date.civil(2007,11,1), "end" => Date.civil(2008,1,31)}, 
               "Y1Q4" => {"year" => "Y1", "quarter"=> "Q4", "start" => Date.civil(2008,2,1), "end" => Date.civil(2008,4,30)}, 
               "Y2Q1" => {"year" => "Y2", "quarter"=> "Q1", "start" => Date.civil(2008,5,1), "end" => Date.civil(2008,7,31)}, 
               "Y2Q2" => {"year" => "Y2", "quarter"=> "Q2", "start" => Date.civil(2008,8,1), "end" => Date.civil(2008,10,31) },
               "Y2Q3" => {"year" => "Y2", "quarter"=> "Q3", "start" => Date.civil(2008,11,1), "end" => Date.civil(2009,1,31) },
               "Y2Q4" => {"year" => "Y2", "quarter"=> "Q4", "start" => Date.civil(2009,2,1), "end" => Date.civil(2009,4,30) } }


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
    @root_directory = File.join(PipelineController.new.path_to_project_dir(@project), "extracted")

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
    @root_directory = File.join(PipelineController.new.path_to_project_dir(@project), "extracted")

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

  def testing
    @projects = Project.all
    @released_projects = Project.find_all_by_status(Project::Status::RELEASED)
    @projects = Project.find(:all)#, :order => 'name')

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
    end

   @quarters = {"Y1Q3" => {"year" => "Y1", "quarter"=> "Q3", "start" => Date.civil(2007,11,1), "end" => Date.civil(2008,1,31)}, 
               "Y1Q4" => {"year" => "Y1", "quarter"=> "Q4", "start" => Date.civil(2008,2,1), "end" => Date.civil(2008,4,30)}, 
               "Y2Q1" => {"year" => "Y2", "quarter"=> "Q1", "start" => Date.civil(2008,5,1), "end" => Date.civil(2008,7,31)}, 
               "Y2Q2" => {"year" => "Y2", "quarter"=> "Q2", "start" => Date.civil(2008,8,1), "end" => Date.civil(2008,10,31) },
               "Y2Q3" => {"year" => "Y2", "quarter"=> "Q3", "start" => Date.civil(2008,11,1), "end" => Date.civil(2009,1,31) },
               "Y2Q4" => {"year" => "Y2", "quarter"=> "Q4", "start" => Date.civil(2009,2,1), "end" => Date.civil(2009,4,30) } }


  end


end
