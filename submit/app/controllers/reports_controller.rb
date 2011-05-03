require 'date'

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

  def nih_spreadsheet
    @freeze_files = ReportsController.get_freeze_files
    @selected_freeze = params[:freeze].nil? ? "" : params[:freeze]
    unless params[:commit].nil? then
      just_filenames = @freeze_files.map { |k, v| v.nil? ? [] : v.map { |v2| v2[1] unless v2.nil? } }.flatten.compact
      selected_freeze_files = just_filenames.find_all { |fname| fname == params[:freeze] }.map { |fname| 
        if fname =~ /^combined_/ then
          date = fname.match(/^combined_(.*)/)[1]
          [ "dmelanogaster_#{date}", "celegans_#{date}" ]
        else
          fname
        end
      }.flatten
      if params[:commit] == "View" then
        ( @data, @headers ) = ReportsController.get_freeze_data(selected_freeze_files)
        @data.each { |d| d.delete_if { |x, y| x.is_a?(Symbol) } }
      elsif params[:commit] == "Download" then
        freeze_file = selected_freeze_files.first
        filename = nil
        if File.exists?("#{RAILS_ROOT}/config/freeze_data/#{freeze_file}.csv") then
          filename = "#{RAILS_ROOT}/config/freeze_data/#{freeze_file}.csv"
        elsif File.exists?("#{RAILS_ROOT}/config/freeze_data/nightly/#{freeze_file}.csv") then
          filename = "#{RAILS_ROOT}/config/freeze_data/nightly/#{freeze_file}.csv"
        end
        if File.exists?(filename) then
          send_file filename, :x_sendfile => true, :type => "text/csv"
        else
          flash[:error] = "File not found"
        end
      end
    end
    @freeze_files = @freeze_files.find { |ff| !ff[0].empty? }[1]
    @freeze_files.each { |ff| ff[0].sub!(/\s+\S+/, '') }
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
    pis = ["Celniker","Henikoff","Karpen","Lai","Lieb","MacAlpine","Oliver","Piano","Snyder","Waterston","White"]
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
    pis = ["Celniker","Henikoff","Karpen","Lai","Lieb","MacAlpine","Oliver","Piano","Snyder","Waterston","White"]
    status = ["New","Uploaded","Validated","DBLoad","Trk found","Configured","Aprvl-PI","Aprvl-DCC","Aprvl-Both","Published"]
    @all_status = status
    active_status = status[0..6]
    @active_status = status[0..6]


    levels = [0,1,2,3]
    level_names = levels.map{|l| "Level "+l.to_s}

    all_distribution_levels_by_pi = Hash.new { |hash, pi| hash[pi] = Hash.new { |hash2, level| hash2[level] = 0} }
    pis.each {|p| all_distribution_levels_by_pi[p]}
    levels.each{|l| pis.each {|p| all_distribution_levels_by_pi[p][l] = 0}}

    undeprecated_projects = Project.all.reject { |p| p.deprecated? }


    # Only use the first version of any project, since it's impossible to "unrelease" a project.
    # This means finding all projects that do not deprecate another project.
    #projects = Project.all
    #projects.clone.each { |p|
    #  if p.deprecated_by_project then
    #   if p.level >= p.deprecated_by_project.level then
    #    projects.delete(p.deprecated_by_project)
    #   else
    #     projects.delete(p)
    #   end
    #  end
    #}

    undeprecated_projects.each { |p|
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


    undeprecated_projects.each do |p| 
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
	    when 'Published' : 10
          else 1
          end 
	all_distributions_by_pi[p.pi.split(",")[0]][status[step-1]] += 1 unless pis.index(p.pi.split(",")[0]).nil? 
	
	all_active_by_pi[p.pi.split(",")[0]][active_status[step-1]] += 1 unless step > active_status.length || pis.index(p.pi.split(",")[0]).nil? 
	@all_active_by_status[active_status[step-1]][p.pi.split(",")[0]] += 1 unless step > active_status.length || pis.index(p.pi.split(",")[0]).nil? 
    end



    @all_new_projects_per_group_per_quarter = Hash.new {|hash,quarter| hash[quarter] = Hash.new { |hash2, pi | hash2[pi] = 0} }
    # initialize to make sure all PIs are included; require each status to be represented
    pis.each {|p| quarters.each{|k,v| @all_new_projects_per_group_per_quarter[k][p] unless v["start"] > Time.now.to_date}}

    undeprecated_projects.each {|p| @all_new_projects_per_group_per_quarter[quarters.find {|k,v| p.created_at.to_date <= v["end"] && p.created_at.to_date >= v["start"]}[0]][p.pi.split(",")[0]] += 1 unless pis.index(p.pi.split(",")[0]).nil? }


    @all_released_projects_per_group_per_quarter = Hash.new {|hash,quarter| hash[quarter] = Hash.new { |hash2, pi | hash2[pi] = 0} }
    # initialize to make sure all PIs are included; require each status to be represented
    pis.each {|p| quarters.each{|k,v| @all_released_projects_per_group_per_quarter[k][p] unless v["start"] > Time.now.to_date}}

    undeprecated_projects.find_all{|p| p.released?}.each{|p|
      if @all_released_projects_per_group_per_quarter.nil? then
        throw :wtf
      end
      quarter = quarters.find{|k,v|
        cmds = Command.find_all_by_project_id_and_status(p.id, Project::Status::RELEASED)
        cmd = cmds.last if cmds.length > 0
        cmd && cmd.end_time.to_date <= v["end"] && cmd.end_time.to_date >= v["start"]
      }
      arp_pgpq = @all_released_projects_per_group_per_quarter[quarter[0]] unless quarter.nil?
      if arp_pgpq then 
        arp_pgpq[p.pi.split(",")[0]] += 1
      else
        nil
      end
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
  
  # Returns full path to most recently generated version of NIH spreadsheet
  def self.nih_spreadsheet_table
    all_nih_spreadsheet = Dir.glob(File.join(nightlies_dir, "output_nih_*.csv"))
    basename = /output_nih_(.*)\.csv/
    all_nih_spreadsheet.sort!{|s1, s2|
      Date.parse(basename.match(s1).to_s) <=> Date.parse(basename.match(s2).to_s)
      }
    all_nih_spreadsheet.last
  end
  
  # uses the NIH spreadsheet table to find all released submissions
  def self.get_released_submissions
    released_subs = []
    cols = ReportsController.get_geoid_columns
    File.open(nih_spreadsheet_table()).each{|line|
      fields = line.split "\t"
      released_subs.push fields if fields[cols["Status"]] == "released"
    }
    return released_subs
  end
  
  # Finds all submissions released and processing
  # since the last time subs were found and marked
  def self.recent_submissions
    cols = ReportsController.get_geoid_columns
    released_subs = ReportsController.get_released_submissions 
    processing_subs = ReportsController.get_processing_submissions # not a parallel format to released!

    already_notified = []
    
    [self.geo_reported_projects_path,
     self.geo_processing_projects_path].each{|file|
      File.open(file).each{|proj|
        next if proj.empty? || proj.strip[0] == "#"
        already_notified.push(proj.split("\t")[0]) # Push the id as a string
      }
    }
    # Remove all subs for which a notification has already been sent
    released_subs.reject!{|item| already_notified.include? item[cols["Submission ID"]] }
    processing_subs.reject!{|item| already_notified.include? item.id.to_s } # convert id to string
    {:released => released_subs, :processing => processing_subs }
  end

  # Finds all submissions that are loaded but not yet published
  def self.get_processing_submissions
    processing_subs = Project.all.select{|p|
     ( Project::Status.status_number(p.status) >= Project::Status.status_number(Project::Status::LOADED) ) &&
     ( Project::Status.status_number(p.status) < Project::Status.status_number(Project::Status::RELEASED) )
    }
    processing_subs
  end

  # Add the passed IDs to the file indicating that
  # an email has been sent regarding the released & processing submissions  
  # Takes: an array of IDs for released subs, and another one for processing
  def self.mark_subs_as_notified(sub_ids_released, sub_ids_processing)
    # Mark released subs
    rel_proj_file = File.open(self.geo_reported_projects_path, "a")
    sub_ids_released.each{|id|
      rel_proj_file.puts "#{id}\t#{Time.now}"
    }
    rel_proj_file.close

    # and repeat for processing subs
    pro_proj_file = File.open(self.geo_processing_projects_path, "a")
    sub_ids_processing.each{|id|
      pro_proj_file.puts "#{id}\t#{Time.now}"
    }
    pro_proj_file.close
  end

  def separate_geo_sra_ids(idstring)
    # Parse the string and separate into two separate arrays
    geoids = []
    sraids = []
    idstring.split(", ").each{|id|
      case id[0,1].downcase
        when "g" then geoids.push id
        when "s" then sraids.push id
        else # TODO handle other things if they exist
      end
    }
    [geoids, sraids]
  end

  # Give a hash of column names => index for that name in the nih spreadsheet.
  def self.get_geoid_columns
    table = File.open(nih_spreadsheet_table())
    cols = table.gets.split("\t")
    table.close
    cols.last.chomp!
    col_hash = Hash.new
    cols.each{|col| col_hash[col] = cols.index(col) }
    col_hash
  end
  
  # Present a table of GEO IDs / SRA IDS
  def geoid_table
    # Get the dates released projects were emailed
    # If a project doens't have a date, mark it
    @future_date = Date.parse("2112-12-21") # Fake later-than-latest date for un-notified-yet projects
    @past_date = Date.parse("2002-02-20") # Fake 'earliest' date for the first group of projects
    reported_projects = Hash.new{@future_date}
    
    seen_dates = Array.new # Array of encountered Date objects
    File.open(self.class.geo_reported_projects_path).each{|rep_proj|
      next if rep_proj.empty? || rep_proj.strip[0] == "#"
      fields = rep_proj.split("\t")
      # Make a hash of ProjectID => date release notified
      notified_date = fields[1].nil? ? nil : Date.parse(fields[1])
      reported_projects[fields[0].to_i] = notified_date
      seen_dates.push notified_date unless (notified_date.nil?) || (seen_dates.include? notified_date)
    }
    seen_dates.sort!

    oldest_release_date = seen_dates[0]
    newest_release_date = seen_dates.last

    seen_dates.insert(0, "any time")
  
    # Then separate out the date lists into start and end for filtering
    @start_dates = Array.new seen_dates
    @end_dates = Array.new seen_dates
  
    # And add special dates
    @start_dates.insert(1, "before #{@start_dates[1]}") # Before earliest date
    @end_dates.push("after #{seen_dates.last.to_s}") # Or after latest date
  
    # Open the NIH spreadsheet table
    # and parse out the relevant information
    cols = ReportsController.get_geoid_columns 
    @projects = []
    ReportsController.get_released_submissions.each{|proj|
      proj_id = proj[cols["Submission ID"]].to_i
      projhash =     
        {
          :id => proj_id,
          :name => proj[cols["Description"]],
          :date_notified => reported_projects[proj_id]
        }
      (projhash[:geoids], projhash[:sraids]) = separate_geo_sra_ids(proj[cols["GEO/SRA IDs"]])  
      @projects.push(projhash)
    }
    # Remove hidden projects
    # Hide nothing by default
    session[:hidden_geo_projs] = :no_projs if session[:hidden_geo_projs].nil?
    # Otherwise, hide if it's been given in a parameter
    session[:hidden_geo_projs] = params[:hide_projs].nil? ? session[:hidden_geo_projs] : params[:hide_projs].to_sym
    case session[:hidden_geo_projs]
      when :no_ids then
        @projects.reject!{|proj| proj[:geoids].empty? && proj[:sraids].empty? }
      when :has_id then
        @projects.reject!{|proj| !(proj[:geoids].empty? && proj[:sraids].empty?) }
      when :no_projs then 
      else # show all projects
    end

    @hidden_projs = session[:hidden_geo_projs]
  
    # Filtering by date
    # If prev_start & end don't exist, set them to oldest & newest
   
    if params["prev_time_start"] =~ /before/ then
      previous_start = @past_date
    else
      previous_start = params["prev_time_start"].nil? ? @past_date : Date.parse(params["prev_time_start"])
    end
    if params["prev_time_end"] =~ /after/ then
      previous_end = @future_date
    else
      previous_end = params["prev_time_end"].nil? ? @future_date : Date.parse(params["prev_time_end"])
    end
    
    # If there's not a current date filter, roll forward the previous one
    if params["commit"] != "Go" then
      @earliest = previous_start
      @latest = previous_end
    else
      # Set up the current filter
      if params["time_start"] =~ /before/ then
        curr_start = @past_date
      else
        curr_start = params["time_start"] == "any time" ? @past_date : Date.parse(params["time_start"])
      end
      # If we want them only from one week, set them the same
      if params["same_week"] == "on" then
        @latest = @earliest = curr_start # We'll increment latest in a moment
      else
        curr_end = (( params["time_end"] == "any time") || (params["time_end"] =~ /after/ )) ? @future_date : Date.parse(params["time_end"])
        @earliest, @latest  = [curr_start, curr_end].sort
      end
      # Then, if earliest = latest then increment latest by one date since these are half-open
      if @earliest == @latest then
        @latest = case @earliest
          when @past_date then oldest_release_date
          when newest_release_date then @future_date 
          else seen_dates[seen_dates.index(@earliest) + 1]
        end
      end

    end
    # -- Remove all projects that don't fit within boundaries --
    # Projects with a date_notified of X were released in the week *BEFORE* X. So
    # If start is Z - "released from Z to..." -- we want all projects with date > Z;
    # If end is Y, we want projects with release date <= Y.
    # So, reject all projects where the date is too early (ie, release date INCLUDES earliest) and
    # where the date is too late -- ie, is anything LATER than latest.
    @projects.reject!{|proj| proj[:date_notified] <= @earliest || proj[:date_notified] > @latest }

    # Sorting
    @new_sort_direction = Hash.new { |hash, column| hash[column] = 'forward' }
    # If sort param given, update sort_list  
    if params[:sort] then
      session[:sort_geo_list] = Hash.new unless session[:sort_geo_list]
      params[:sort].each_pair { |column, direction| session[:sort_geo_list][column.to_sym] = [ direction, Time.now ] }
    end
    
    # If there's non-default sorting, apply the sorts
    if session[:sort_geo_list] then
      sorts = session[:sort_geo_list].sort_by { |column, sortby| sortby[1] }.reverse.map { |column, sortby| column }      
      @projects = @projects.sort { |p1, p2|
        p1_attrs = sorts.map { |col|
          col = col.to_sym
          session[:sort_geo_list][col] = [] if session[:sort_geo_list][col].nil?
          sort_attr = (session[:sort_geo_list][col][0] == 'backward') ?  p2[col] : p1[col]
          sort_attr = sort_attr.nil? ? -999 : sort_attr
        } << p1.id
        p2_attrs = sorts.map { |col|
          session[:sort_geo_list][col] = [] if session[:sort_geo_list][col].nil?
          sort_attr = (session[:sort_geo_list][col][0] == 'backward') ?  p1[col] : p2[col] 
          sort_attr = sort_attr.nil? ? -999 : sort_attr
        } << p2.id
        p1_attrs.nil_flatten_compare p2_attrs
      }   
      session[:sort_geo_list].each_pair { |col, srtby| @new_sort_direction[col] = 'backward' if srtby[0] == 'forward' && sorts[0] == col }
    else    
      @projects = @projects.sort { |p1, p2| p1[:name] <=> p2[:name] }
    end

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
	       "Y4Q4" => {"year" => "Y4", "quarter"=> "Q4", "start" => Date.civil(2011,2,1), "end" => Date.civil(2011,4,30)}, 
               "Y5Q1" => {"year" => "Y5", "quarter"=> "Q1", "start" => Date.civil(2011,5,1), "end" => Date.civil(2011,7,31)},
               "Y5Q2" => {"year" => "Y5", "quarter"=> "Q2", "start" => Date.civil(2011,8,1), "end" => Date.civil(2011,10,31)},
               "Y5Q3" => {"year" => "Y5", "quarter"=> "Q3", "start" => Date.civil(2011,11,1), "end" => Date.civil(2012,1,31)},
               "Y5Q4" => {"year" => "Y5", "quarter"=> "Q4", "start" => Date.civil(2012,2,1), "end" => Date.civil(2012,4,30)} 

}


  end
  def self.geo_reported_projects_path
    "#{RAILS_ROOT}/config/freeze_data/geoid_table/released_and_notified.tsv"
  end
  def self.geo_processing_projects_path
    "#{RAILS_ROOT}/config/freeze_data/geoid_table/processing_and_notified.tsv"
  end
  def self.nightlies_dir
    "#{RAILS_ROOT}/config/freeze_data/nightly/"
  end
  def self.get_freeze_files
    freeze_files = Hash.new { |h, k| h[k] = Array.new }
    freeze_files[""] = [ nil ]
    freeze_dir = "#{RAILS_ROOT}/config/freeze_data/"
    if File.directory? freeze_dir then
      Dir.glob(File.join(freeze_dir, "output_nih_*.csv")).each { |f| 
        fname = File.basename(f)[0..-5]
        (organism, date) = fname.split(/_/)
        organism = organism[0..0].upcase + ". " + organism[1..-1]
        freeze_files[organism].push [ date, fname ]
      }
    end

    # Nightlies
    freeze_dir = "#{RAILS_ROOT}/config/freeze_data/nightly/"
    if File.directory? freeze_dir then
      Dir.glob(File.join(freeze_dir, "output_nih_*.csv")).each { |f| 
        fname = File.basename(f)[0..-5]
        (organism, date) = fname.split(/nih_/)
        organism = organism[0..0].upcase + ". " + organism[1..-1]
        freeze_files[organism + " nightlies"].push [ date, fname ]
      }
    end

    freeze_files = freeze_files.to_a
    freeze_files.each { |file, dates| dates.sort! { |d1, d2| Date.parse(d2[0]) <=> Date.parse(d1[0]) } }
    freeze_files.each { |file, dates| dates.each { |date| date[0] += " #{date[1][0..3]}" unless date.nil?; }; dates.first[0] += " (newest)" if dates.first }
    return freeze_files
  end
  def self.get_freeze_data(freeze_files)
    data = Array.new
    headers = []
    freeze_files.each { |freeze_file|
      filename = nil
      if File.exists?("#{RAILS_ROOT}/config/freeze_data/#{freeze_file}.csv") then
        filename = "#{RAILS_ROOT}/config/freeze_data/#{freeze_file}.csv"
      elsif File.exists?("#{RAILS_ROOT}/config/freeze_data/nightly/#{freeze_file}.csv") then
        filename = "#{RAILS_ROOT}/config/freeze_data/nightly/#{freeze_file}.csv"
      end

      if filename then
        File.open(filename) { |f|
          headers = f.gets.chomp.split(/\t/)
          while ((line = f.gets) != nil) do
            fields = line.chomp.split(/\t/).map { |field| (field == "" ? "N/A" : field) }
            d = Hash.new; headers.each_index { |n| d[headers[n]] = (fields[n].nil? ? nil : fields[n].gsub(/^"|"$/, '')) }
            data.push d
          end
        }
      end
    }
    self.extract_and_attach_factor_info(data)
    return [ data, headers ]
  end
  def self.extract_and_attach_factor_info(freeze_data)
    # We group some fields together and put them into symbol-keyed entries in the @freeze_data hash
    # because older generated spreadsheets had these fields separate
    # This is the mapping of human-readable column name to grouped field, which gets used when
    # defining a matrix view
    @freeze_header_translation = {
      "Antibody" => :antibodies,
      "Platform" => :array_platforms,
      "Compound" => :compounds,
      "RNAi Target" => :rnai_targets,
      "Stage/Treatment" => :stages,
    }

    if freeze_data.find { |project_info| project_info["Experimental Factor"] } then
      freeze_data.each { |project_info| 
        factors = project_info["Experimental Factor"].split(/[;,]\s*/).flatten.uniq.inject(Hash.new { |h, k| h[k] = Array.new }) { |h, factor| 
          (k,v) = factor.split(/=/)
          h[k].push v
          h
        }
        treatments = project_info["Treatment"].split(/[;,]\s*/).flatten.uniq.inject(Hash.new { |h, k| h[k] = Array.new }) { |h, treatment| 
          (k,v) = treatment.split(/=/)
          h[k].push v
          h
        }

        project_info[:antibodies]      = factors["AbName"].zip(factors["Target"]).map { |pair| pair.join("=>") }
        project_info[:array_platforms] = (factors["Platform"].blank? ? factors["ArrayPlatform"] : factors["Platform"])
        project_info[:compounds]       = factors["SaltConcentration"].map  { |compound| "SaltConcentration=#{compound}" }
        project_info[:rnai_targets]    = treatments["RNAiTarget"]
        stage_info = (project_info["Stage"] || project_info["Stage/Treatment"] || "")
        stage_info_m = stage_info.match(/^(.*):/)
        project_info[:stages]          = stage_info_m.nil? ? stage_info.split(/,\s*/) : [ stage_info_m[1] ]
        project_info["Stage"]          = stage_info_m.nil? ? stage_info.split(/,\s*/) : [ stage_info_m[1] ]
        project_info[:submission_id]   = project_info["Submission ID"].sub(/ .*/, '')

        project_info[:antibodies] = ["N/A"] if project_info[:antibodies].size == 0
        project_info[:array_platforms] = ["N/A"] if project_info[:array_platforms].size == 0
        project_info[:compounds] = ["N/A"] if project_info[:compounds].size == 0
        project_info[:rnai_targets] = ["N/A"] if project_info[:rnai_targets].size == 0
        project_info[:stages] = ["N/A"] if project_info[:stages].size == 0
      }
    else
      freeze_data.each { |project_info|
        project_info[:antibodies] = project_info["Antibody"].split(/, /)
        project_info[:array_platforms] = project_info["Platform"].split(/, /)
        project_info[:compounds] = project_info["Compound"].split(/, /)
        project_info[:rnai_targets] = project_info["RNAi Target"].split(/, /)
        project_info[:stages] = project_info["Stage/Treatment"].split(/, /)
        project_info[:submission_id]   = project_info["Submission ID"].sub(/ .*/, '')

        project_info[:antibodies] = ["N/A"] if project_info[:antibodies].size == 0
        project_info[:array_platforms] = ["N/A"] if project_info[:array_platforms].size == 0
        project_info[:compounds] = ["N/A"] if project_info[:compounds].size == 0
        project_info[:rnai_targets] = ["N/A"] if project_info[:rnai_targets].size == 0
        project_info[:stages] = ["N/A"] if project_info[:stages].size == 0
      }
    end
  end
end

