class Array
  def median
    self.size % 2 == 1 ? self.sort[self.size/2] : self.sort[self.size/2-1..self.size/2].sum.to_f/2
  end
  def mean
    self.sum/self.size
  end
  def variance
    numbers = self
    n = 0;
    mean = numbers.mean;
    s = 0.0;
    numbers.each { |x|
      n = n+1
      delta = x-mean
      s = s + delta*delta         
    }
    return (s/(n))
  end
  def stdev
    numbers = self;
    Math.sqrt(numbers.variance)      
  end
  def mode
    numbers = self
    c_n_count = 0 # Current number count
    length = numbers.length - 1
    amount = {} # New array for the number of times each number occurs in the array
    for x in 0..length
      c_number = numbers[x]
      for y in 0..length
        if numbers[y] == c_number # If the current number is equal to the upper level current number
          c_n_count = c_n_count + 1
        end
      end
      amount[x] = c_n_count # Add the total number of occurences in the value array
      c_n_count = 0
    end
    max = 0
    high_number = 0
    for x in 0..length
      if amount[x] > max # If the current number breaks the previous high record
        max = amount[x] # Reset the max to this new record
        high_number = x # Set the new most common number to that number
      end
    end
    return numbers[high_number]
  end
end


class ReportsController < ApplicationController
  before_filter :login_required

  def unescape(str)
    str.gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
      [$1.delete('%')].pack('H*')
    end
  end

  def nih_summary
    unless params[:filter] then
      redirect_to :action => :nih_summary, :filter => "released"
      return
    end

    @filter = params[:filter] == "released" ? { "Released Data Sets" => true } : { "Unreleased Data Sets" => false }
    @all_types_by_project = TrackTag.find(:all, :conditions => { :name => "Feature" }, :select => "cvterm, project_id", :group => "cvterm, project_id")

    if params[:mode] == "tsv" then
      @tsv = true
      headers['Content-Type'] = "text/csv"
      render :action => :nih_summary_tsv, :layout => false
    end
  end


  def vetting_stats
    index
  end

  def weekly_summary
    index
  end

  def publish
    @time_format = "%a, %b %d, %Y (%H:%M)"
    unpublish = params[:publish_date].empty?
    unless current_user.is_a?(Moderator) then
      flash[:error] = "Only moderators can update publication dates."
      redirect_to :action => "list"
      return
    end
    publish_projects = Hash.new
    begin
      publish_projects[:gbrowse] = params[:publish][:gbrowse].nil? ? Array.new : params[:publish][:gbrowse].keys.map { |project_id| Project.find(project_id) }
      publish_projects[:modmine] = params[:publish][:modmine].nil? ? Array.new : params[:publish][:modmine].keys.map { |project_id| Project.find(project_id) }
      publish_projects[:geo] = params[:publish][:geo].nil? ? Array.new : params[:publish][:geo].keys.map { |project_id| Project.find(project_id) }
    rescue
      flash[:error] = "Couldn't find all projects with to publish"
      redirect_to :action => "publication"
      return
    end
    unless unpublish then
      date = params[:publish_date]
      if (date !~ /\d\d\d\d-\d\d-\d\d \d\d:\d\d/) then
        if Time.parse(date).strftime(@time_format) != date then
          flash[:warning] = "Nonstandard time format. To avoid this message use YYYY-MM-DD HH:MM."
        end
      end
      new_date = Time.parse(date)
    end
    publish_types = {
      :gbrowse => PublishToGbrowse,
      :modmine => PublishToModMine,
      :geo     => PublishToGEO
    }
    publish_types.each { |type, classname|
      publish_projects[type].each { |p|
        if unpublish then
          pub = classname.find_all_by_project_id(p.id)
          pub.each { |pub1| pub1.destroy }
        else
          pub = classname.new(:project => p)
          pub.save
          pub.start_time = new_date
          pub.end_time = new_date
          pub.user = current_user
          pub.save
        end
      }
    }
    redirect_to :action => "publication"
  end
  def publication
    @time_format = "%a, %b %d, %Y (%H:%M)"
    @released_projects = Project.find_all_by_status_and_deprecated_project_id(Project::Status::RELEASED, nil)


    session[:show_filter_pis] = params[:pi].map { |p| p == "" ? nil : p }.compact unless params[:pi].nil?
    @pis_to_view = (session[:show_filter_pis].nil? || session[:show_filter_pis] == "") ? [] : session[:show_filter_pis]

    @filter_by_ids = session[:filter_by_ids].nil? ? Array.new : session[:filter_by_ids]
    unless params[:filter_by_ids].nil?
      @filter_by_ids = params[:filter_by_ids].split(/,? /).reject { |i| i != i.to_i.to_s }.map { |i| i.to_i }
      session[:filter_by_ids] = @filter_by_ids
      redirect_to :action => "publication"
    end

    @pis = User.all.map { |u| u.lab }.uniq
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
    if @pis_to_view && @pis_to_view.length > 0 then
      @released_projects = @released_projects.find_all { |p| @pis_to_view.include?(p.pi) }
    end
    if session[:sort_list] then
      sorts = session[:sort_list].sort_by { |column, sortby| sortby[1] }.reverse.map { |column, sortby| column }
      @released_projects = @released_projects.sort { |p1, p2|
        p1_attrs = sorts.map { |col| (session[:sort_list][col][0] == 'backward') ?  p2.send(col) : p1.send(col) } << p1.id
        p2_attrs = sorts.map { |col| (session[:sort_list][col][0] == 'backward') ?  p1.send(col) : p2.send(col) } << p2.id
        p1_attrs.nil_flatten_compare p2_attrs
      }
      session[:sort_list].each_pair { |col, srtby| @new_sort_direction[col] = 'backward' if srtby[0] == 'forward' && sorts[0] == col }
    else
      @released_projects = @released_projects.sort { |p1, p2| p2.id <=> p1.id }
    end

    @all_released_projects = @released_projects
    if @filter_by_ids.size > 0 then
      @released_projects = @released_projects.find_all { |rp| @filter_by_ids.include?(rp.id) }
    else
      # Paginate
      if params[:page_size] then
        begin
          session[:page_size] = params[:page_size].to_i
        rescue
        end
      end
      session[:page_size] = 25 if session[:page_size].nil?
      page_size = session[:page_size]
      page_offset = 0
      if params[:page] then
        page_offset = [(params[:page].to_i-1), 0].max * page_size
      end
      page_end = (page_offset + page_size)
      @cur_page = (page_offset / page_size) + 1
      @num_pages = @released_projects.size / page_size
      @num_pages += 1 if @released_projects.size % page_size != 0
      @has_next_page = @cur_page != @num_pages
      @has_prev_page = @cur_page != 1
      @released_projects = @released_projects[page_offset...page_end]
    end

    @all_gbrowse_publishes = PublishToGbrowse.all
    @all_modmine_publishes = PublishToModMine.all
    @all_geo_publishes = PublishToGEO.all
  end

  def data_matrix
    levels
  end

  def levels
    index
    pis = ["Celniker","Henikoff","Karpen","Lai","Lieb","MacAlpine","Piano","Snyder","Waterston","White"]
    levels = [0,1,2,3]
    level_names = levels.map{|l| "Level "+l.to_s}

    all_distributions_by_pi = Hash.new { |hash, pi| hash[pi] = Hash.new { |hash2, level| hash2[level] = 0} }
    pis.each {|p| all_distributions_by_pi[p]}
    levels.each{|l| pis.each {|p| all_distributions_by_pi[p][l] = 0}}

    Project.all.reject { |p| p.deprecated? }.each {|p|
	all_distributions_by_pi[p.pi.split(",")[0]][p.level] += 1  unless pis.index(p.pi.split(",")[0]).nil? 
	}	
    @all_distributions_by_pi = all_distributions_by_pi
  end

  def index_table
    index
  end


  def index

   quarters = {"Y1Q3" => {"year" => "Y1", "quarter"=> "Q3", "start" => Date.civil(2007,11,1), "end" => Date.civil(2008,1,31)},
               "Y1Q4" => {"year" => "Y1", "quarter"=> "Q4", "start" => Date.civil(2008,2,1), "end" => Date.civil(2008,4,30)},
	       "Y2Q1" => {"year" => "Y2", "quarter"=> "Q1", "start" => Date.civil(2008,5,1), "end" => Date.civil(2008,7,31)},
               "Y2Q2" => {"year" => "Y2", "quarter"=> "Q2", "start" => Date.civil(2008,8,1), "end" => Date.civil(2008,10,31) },
               "Y2Q3" => {"year" => "Y2", "quarter"=> "Q3", "start" => Date.civil(2008,11,1), "end" => Date.civil(2009,1,31) },
	       "Y2Q4" => {"year" => "Y2", "quarter"=> "Q4", "start" => Date.civil(2009,2,1), "end" => Date.civil(2009,4,30) },
               "Y3Q1" => {"year" => "Y3", "quarter"=> "Q1", "start" => Date.civil(2009,5,1), "end" => Date.civil(2009,7,31)},
               "Y3Q2" => {"year" => "Y3", "quarter"=> "Q2", "start" => Date.civil(2009,8,1), "end" => Date.civil(2009,10,31)},
               "Y3Q3" => {"year" => "Y3", "quarter"=> "Q3", "start" => Date.civil(2009,11,1), "end" => Date.civil(2010,1,31)},
               "Y3Q4" => {"year" => "Y3", "quarter"=> "Q4", "start" => Date.civil(2010,2,1), "end" => Date.civil(2010,4,30)},
	       "Y4Q1" => {"year" => "Y4", "quarter"=> "Q1", "start" => Date.civil(2010,5,1), "end" => Date.civil(2010,7,31)},
	       "Y4Q2" => {"year" => "Y4", "quarter"=> "Q2", "start" => Date.civil(2010,8,1), "end" => Date.civil(2010,10,31)},
               "Y4Q3" => {"year" => "Y4", "quarter"=> "Q3", "start" => Date.civil(2010,11,1), "end" => Date.civil(2011,1,31)},
               "Y4Q4" => {"year" => "Y4", "quarter"=> "Q4", "start" => Date.civil(2011,2,1), "end" => Date.civil(2011,4,30)} }


    @quarters = quarters
    #these are the pis to include in the display - modify to add additional pis	
    pis = ["Celniker","Henikoff","Karpen","Lai","Lieb","MacAlpine","Piano","Snyder","Waterston","White"]
    status = ["New","Uploaded","Validated","DBLoad","Trk found","Configured","Aprvl-PI","Aprvl-DCC","Aprvl-Both","Published"]
    @all_status = status
    active_status = status[0..6]
    @active_status = status[0..6]


    levels = [0,1,2,3]
    level_names = levels.map{|l| "Level "+l.to_s}

    all_distribution_levels_by_pi = Hash.new { |hash, pi| hash[pi] = Hash.new { |hash2, level| hash2[level] = 0} }
    pis.each {|p| all_distribution_levels_by_pi[p]}
    levels.each{|l| pis.each {|p| all_distribution_levels_by_pi[p][l] = 0}}

    # Only use the first version of any project, since it's impossible to "unrelease" a project.
    # This means finding all projects that do not deprecate another project.
    projects = Project.all
    projects.clone.each { |p|
      if p.deprecated_by_project then
       if p.level >= p.deprecated_by_project.level then
        projects.delete(p.deprecated_by_project)
       else
         projects.delete(p)
       end
      end
    }

    projects.each { |p|
      all_distribution_levels_by_pi[p.pi.split(",")[0]][p.level] += 1  unless pis.index(p.pi.split(",")[0]).nil?
    }

    @all_distribution_levels_by_pi = all_distribution_levels_by_pi


    # initialize to make sure all PIs are included; require each status to be represented
    all_distributions_by_pi = Hash.new { |hash, pi| hash[pi] = Hash.new { |hash2, status| hash2[status] = 0} }
    pis.each {|p| all_distributions_by_pi[p]}
    all_active_by_pi = Hash.new { |hash, pi| hash[pi] = Hash.new { |hash2, status| hash2[status] = 0} }
    pis.each {|p| all_active_by_pi[p]}

    active_status.each{|s| pis.each {|p| all_active_by_pi[p][s] = 0}}
    status.each{|s| pis.each {|p| all_distributions_by_pi[p][s] = 0}}
    
    @all_active_by_status = Hash.new { |hash, pi| hash[pi] = Hash.new { |hash2, status| hash2[status] = 0} }
    active_status.each{|s| pis.each {|p| @all_active_by_status[s][p] = 0}}


    projects.each do |p| 
          step = 1
	  #identify what step its at
          step = case p.status  
            when (Project::Status::NEW ) : 1
	    when Project::Status::UPLOAD_FAILED : 1
	    when Project::Status::UPLOADING : 1
            when (Project::Status::UPLOADED) : 2
            when (Project::Status::VALIDATION_FAILED) : 2
	    when (Project::Status::VALIDATING) : 2
            when (Project::Status::EXPAND_FAILED) : 2
            when (Project::Status::EXPANDED) : 2
            when Project::Status::VALIDATED : 3
	    when Project::Status::LOAD_FAILED : 3
	    when Project::Status::LOADING : 3
	    when Project::Status::UNLOADING : 3
            when Project::Status::LOADED : 4
	    when Project::Status::FINDING_FAILED : 4
	    when Project::Status::FINDING  : 4
            when Project::Status::FOUND : 5
	    when Project::Status::CONFIGURING  : 5
            when Project::Status::CONFIGURED : 6
	    when Project::Status::AWAITING_RELEASE : 6
	    when Project::Status::RELEASE_REJECTED : 7
            when (Project::Status::USER_RELEASED ) : 8
            when (Project::Status::DCC_RELEASED) : 9
            when (Project::Status::RELEASED) : 10   #released to the public
	    when 'Published' : 11
          else 1
          end 
	all_distributions_by_pi[p.pi.split(",")[0]][status[step-1]] += 1 unless pis.index(p.pi.split(",")[0]).nil? 
	
	all_active_by_pi[p.pi.split(",")[0]][active_status[step-1]] += 1 unless step > active_status.length || pis.index(p.pi.split(",")[0]).nil? 
	@all_active_by_status[active_status[step-1]][p.pi.split(",")[0]] += 1 unless step > active_status.length || pis.index(p.pi.split(",")[0]).nil? 
    end



    @all_new_projects_per_group_per_quarter = Hash.new {|hash,quarter| hash[quarter] = Hash.new { |hash2, pi | hash2[pi] = 0} }
    # initialize to make sure all PIs are included; require each status to be represented
    pis.each {|p| quarters.each{|k,v| @all_new_projects_per_group_per_quarter[k][p] unless v["start"] > Time.now.to_date}}

    undeprecated_projects = Project.all.reject { |p| p.deprecated? }
    undeprecated_projects.each {|p| @all_new_projects_per_group_per_quarter[quarters.find {|k,v| p.created_at.to_date <= v["end"] && p.created_at.to_date >= v["start"]}[0]][p.pi.split(",")[0]] += 1 unless pis.index(p.pi.split(",")[0]).nil? }


    @all_released_projects_per_group_per_quarter = Hash.new {|hash,quarter| hash[quarter] = Hash.new { |hash2, pi | hash2[pi] = 0} }
    # initialize to make sure all PIs are included; require each status to be represented
    pis.each {|p| quarters.each{|k,v| @all_released_projects_per_group_per_quarter[k][p] unless v["start"] > Time.now.to_date}}

    undeprecated_projects.find_all{|p| p.released?}.each{|p| @all_released_projects_per_group_per_quarter[quarters.find{|k,v|
      cmds = Command.find_all_by_project_id_and_status(p.id, Project::Status::RELEASED)
      cmd = cmds.last if cmds.length > 0
      cmd && cmd.end_time.to_date <= v["end"] && cmd.end_time.to_date >= v["start"]}[0]][p.pi.split(",")[0]] += 1
    }


    @all_new_projects_per_quarter = Hash.new {|hash,quarter| hash[quarter] = 0} 
    undeprecated_projects.each {|p| @all_new_projects_per_quarter[quarters.find {|k,v| p.created_at.to_date <= v["end"] && p.created_at.to_date >= v["start"]}[0]] += 1  unless pis.index(p.pi.split(",")[0]).nil? }


    all_distributions_by_user = Hash.new { |hash, user| hash[user] = Hash.new { |hash2, status| hash2[status] = 0} }
    undeprecated_projects.each { |p| all_distributions_by_user[p.user.login][p.status] += 1 }

    @all_distributions_by_status = Hash.new {|hash,status| hash[status] = 0}
    undeprecated_projects.each {|p| @all_distributions_by_status[p.status] += 1 }

    overall_distributions = Hash.new { |hash, status| hash[status] = 0 }
    undeprecated_projects.each { |p| overall_distributions[p.status] += 1 }
    @all_distributions = overall_distributions


    @all_projects_by_pi = Hash.new { |hash, pi| hash[pi] = Hash.new { |hash2, status| hash2[status] = 0} }
    pis.each {|p| @all_projects_by_pi[p]}
    status = ["Active","Released"]
    @bi_status = status
    status.each{|s| pis.each {|p| @all_projects_by_pi[p][s] = 0}}
    undeprecated_projects.each do |p|
          step = 0
          #identify what step its at
          step = case p.status
            when (Project::Status::NEW || Project::Status::UPLOAD_FAILED || Project::Status::UPLOADING) : 1
            when (Project::Status::UPLOADED || Project::Status::VALIDATION_FAILED || Project::Status::VALIDATING || Project::Status::EXPAND_FAILED) : 1
            when (Project::Status::VALIDATED || Project::Status::LOAD_FAILED || Project::Status::LOADING || Project::Status::UNLOADING) : 1
            when (Project::Status::LOADED || Project::Status::FINDING_FAILED || Project::Status::FINDING ) : 1
            when (Project::Status::FOUND || Project::Status::CONFIGURING)  : 1
            when (Project::Status::CONFIGURED || Project::Status::AWAITING_RELEASE) : 1
	    when (Project::Status::RELEASE_REJECTED ) : 1
            when (Project::Status::USER_RELEASED ) : 2
            when (Project::Status::DCC_RELEASED) : 2
            when (Project::Status::RELEASED) : 2  
          else 1
          end
	@all_projects_by_pi[p.pi.split(",")[0]][@bi_status[step-1]] += 1 unless pis.index(p.pi.split(",")[0]).nil?

    end


    @all_projects = undeprecated_projects

  end

  def status_table
    status

    render :partial => 'status_table'
  end

  def status
    @projects = Project.all.reject { |p| p.deprecated? }

    session[:status_display_type] = params[:display_type] unless params[:display_type].nil?
    session[:status_display_date] = params[:display_date] unless params[:display_date].nil?
    session[:status_show_status] = params[:show_status] unless params[:show_status].nil?

    @display_type = session[:status_display_type] || 'compact'
    @display_date = session[:status_display_date] || 'quarter'
    @show_status = session[:status_show_status] || 'all'

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
               "Y2Q4" => {"year" => "Y2", "quarter"=> "Q4", "start" => Date.civil(2009,2,1), "end" => Date.civil(2009,4,30) },
	       "Y3Q1" => {"year" => "Y3", "quarter"=> "Q1", "start" => Date.civil(2009,5,1), "end" => Date.civil(2009,7,31)},
	       "Y3Q2" => {"year" => "Y3", "quarter"=> "Q2", "start" => Date.civil(2009,8,1), "end" => Date.civil(2009,10,31)},
               "Y3Q3" => {"year" => "Y3", "quarter"=> "Q3", "start" => Date.civil(2009,11,1), "end" => Date.civil(2010,1,31)},
	       "Y3Q4" => {"year" => "Y3", "quarter"=> "Q4", "start" => Date.civil(2010,2,1), "end" => Date.civil(2010,4,30)},
	       "Y4Q1" => {"year" => "Y4", "quarter"=> "Q1", "start" => Date.civil(2010,5,1), "end" => Date.civil(2010,7,31)},
               "Y4Q2" => {"year" => "Y4", "quarter"=> "Q2", "start" => Date.civil(2010,8,1), "end" => Date.civil(2010,10,31)},
	       "Y4Q3" => {"year" => "Y4", "quarter"=> "Q3", "start" => Date.civil(2010,11,1), "end" => Date.civil(2011,1,31)},
	       "Y4Q4" => {"year" => "Y4", "quarter"=> "Q4", "start" => Date.civil(2011,2,1), "end" => Date.civil(2011,4,30)} }


  end


end

