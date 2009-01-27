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

  def index

   quarters = {"Y1Q3" => {"year" => "Y1", "quarter"=> "Q3", "start" => Date.civil(2007,11,1), "end" => Date.civil(2008,1,31)}, 
               "Y1Q4" => {"year" => "Y1", "quarter"=> "Q4", "start" => Date.civil(2008,2,1), "end" => Date.civil(2008,4,30)}, 
               "Y2Q1" => {"year" => "Y2", "quarter"=> "Q1", "start" => Date.civil(2008,5,1), "end" => Date.civil(2008,7,31)}, 
               "Y2Q2" => {"year" => "Y2", "quarter"=> "Q2", "start" => Date.civil(2008,8,1), "end" => Date.civil(2008,10,31) },
               "Y2Q3" => {"year" => "Y2", "quarter"=> "Q3", "start" => Date.civil(2008,11,1), "end" => Date.civil(2009,1,31) },
               "Y2Q4" => {"year" => "Y2", "quarter"=> "Q4", "start" => Date.civil(2009,2,1), "end" => Date.civil(2009,4,30) } }
    @quarters = quarters
    #these are the pis to include in the display - modify to add additional pis	
    pis = ["Celniker","Henikoff","Karpen","Lai","Lieb","MacAlpine","Piano","Snyder","Waterston","White"]
    status = ["New","Uploaded","Validated","DBLoad","Trk found","Configured","Needs attn", "Aprvl-PI","Aprvl-DCC","Aprvl-Both","Published"]
    @all_status = status
    active_status = status[0..6]
    @active_status = status[0..6]

    # initialize to make sure all PIs are included; require each status to be represented
    all_distributions_by_pi = Hash.new { |hash, pi| hash[pi] = Hash.new { |hash2, status| hash2[status] = 0} }
    pis.each {|p| all_distributions_by_pi[p]}
    #Project.all.each { |p| all_distributions_by_pi[p.user.pi.split(",")[0]][p.status] += 1 }
    all_active_by_pi = Hash.new { |hash, pi| hash[pi] = Hash.new { |hash2, status| hash2[status] = 0} }
    pis.each {|p| all_active_by_pi[p]}

    active_status.each{|s| pis.each {|p| all_active_by_pi[p][s] = 0}}
    status.each{|s| pis.each {|p| all_distributions_by_pi[p][s] = 0}}
    
    @all_active_by_status = Hash.new { |hash, pi| hash[pi] = Hash.new { |hash2, status| hash2[status] = 0} }
    active_status.each{|s| pis.each {|p| @all_active_by_status[s][p] = 0}}


    Project.all.each do |p| 
          step = 1
	  #identify what step its at
          step = case p.status  
            when (Project::Status::NEW || Project::Status::UPLOAD_FAILED || Project::Status::UPLOADING) : 1
            when (Project::Status::UPLOADED || Project::Status::VALIDATION_FAILED || Project::Status::VALIDATING || Proejct::Status::EXPAND_FAILED) : 2
            when (Project::Status::VALIDATED || Project::Status::LOAD_FAILED || Project::Status::LOADING || Project::Status::UNLOADING) : 3
            when (Project::Status::LOADED || Project::Status::FINDING_FAILED || Project::Status::FINDING ) : 4
            when (Project::Status::FOUND || Project::Status::CONFIGURING)  : 5
            when (Project::Status::CONFIGURED || Project::Status::AWAITING_RELEASE) : 6
	    when (Project::Status::RELEASE_REJECTED ) : 7
            when (Project::Status::USER_RELEASED ) : 8
            when (Project::Status::DCC_RELEASED) : 9
            when (Project::Status::RELEASED) : 10   #released to the public
	    when 'Published' : 11
          else 1
          end 
	all_distributions_by_pi[p.user.pi.split(",")[0]][status[step-1]] += 1  unless pis.index(p.user.pi.split(",")[0]).nil? 
	
	all_active_by_pi[p.user.pi.split(",")[0]][active_status[step-1]] += 1	unless step > active_status.length || pis.index(p.user.pi.split(",")[0]).nil? 
	@all_active_by_status[active_status[step-1]][p.user.pi.split(",")[0]] += 1 unless step > active_status.length || pis.index(p.user.pi.split(",")[0]).nil? 
    end



    @all_new_projects_per_group_per_quarter = Hash.new {|hash,quarter| hash[quarter] = Hash.new { |hash2, pi | hash2[pi] = 0} }
    # initialize to make sure all PIs are included; require each status to be represented
    pis.each {|p| quarters.each{|k,v| @all_new_projects_per_group_per_quarter[k][p] unless v["start"] > Time.now.to_date}}

    Project.all.each {|p| @all_new_projects_per_group_per_quarter[quarters.find {|k,v| p.created_at.to_date <= v["end"] && p.created_at.to_date >= v["start"]}[0]][p.user.pi.split(",")[0]] += 1 unless pis.index(p.user.pi.split(",")[0]).nil? }


    @all_released_projects_per_group_per_quarter = Hash.new {|hash,quarter| hash[quarter] = Hash.new { |hash2, pi | hash2[pi] = 0} }
    # initialize to make sure all PIs are included; require each status to be represented
    pis.each {|p| quarters.each{|k,v| @all_released_projects_per_group_per_quarter[k][p] unless v["start"] > Time.now.to_date}}

    Project.all.find_all{|p| p.status==Project::Status::RELEASED}.each{|p| @all_released_projects_per_group_per_quarter[quarters.find{|k,v| Command.find_all_by_project_id(p.id).find_all{|c| c.status==Project::Status::RELEASED}.last.updated_at.to_date <= v["end"] && Command.find_all_by_project_id(p.id).find_all{|c| c.status==Project::Status::RELEASED}.last.updated_at.to_date >= v["start"]}[0]][p.user.pi.split(",")[0]] += 1 }


    @all_new_projects_per_quarter = Hash.new {|hash,quarter| hash[quarter] = 0} 
    Project.all.each {|p| @all_new_projects_per_quarter[quarters.find {|k,v| p.created_at.to_date <= v["end"] && p.created_at.to_date >= v["start"]}[0]] += 1  unless pis.index(p.user.pi.split(",")[0]).nil? }


    all_distributions_by_user = Hash.new { |hash, user| hash[user] = Hash.new { |hash2, status| hash2[status] = 0} }
    Project.all.each { |p| all_distributions_by_user[p.user.login][p.status] += 1 }

    @all_distributions_by_status = Hash.new {|hash,status| hash[status] = 0}
    Project.all.each {|p| @all_distributions_by_status[p.status] += 1 }

    overall_distributions = Hash.new { |hash, status| hash[status] = 0 }
    Project.all.each { |p| overall_distributions[p.status] += 1 }
    @all_distributions = overall_distributions


    @all_projects_by_pi = Hash.new { |hash, pi| hash[pi] = Hash.new { |hash2, status| hash2[status] = 0} }
    pis.each {|p| @all_projects_by_pi[p]}
    status = ["Active","Released"]
    @bi_status = status
    status.each{|s| pis.each {|p| @all_projects_by_pi[p][s] = 0}}
    Project.all.each do |p|
          step = 0
          #identify what step its at
          step = case p.status
            when (Project::Status::NEW || Project::Status::UPLOAD_FAILED || Project::Status::UPLOADING) : 1
            when (Project::Status::UPLOADED || Project::Status::VALIDATION_FAILED || Project::Status::VALIDATING || Proejct::Status::EXPAND_FAILED) : 1
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
	@all_projects_by_pi[p.user.pi.split(",")[0]][@bi_status[step-1]] += 1 unless pis.index(p.user.pi.split(",")[0]).nil?

    end


    @all_projects = Project.all

    @project_pi = current_user.pi

  end

  def status_table
    status

    render :partial => 'status_table'
  end

  def status
    @projects = Project.all
    @projects = Project.find(:all)#, :order => 'name')

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
               "Y2Q4" => {"year" => "Y2", "quarter"=> "Q4", "start" => Date.civil(2009,2,1), "end" => Date.civil(2009,4,30) } }


  end


end

