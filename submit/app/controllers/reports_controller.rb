class ReportsController < ApplicationController
  before_filter :login_required

  def index

   quarters = {"Y1Q3" => {"year" => "Y1", "quarter"=> "Q3", "start" => Date.civil(2007,11,1), "end" => Date.civil(2008,1,31)}, 
               "Y1Q4" => {"year" => "Y1", "quarter"=> "Q4", "start" => Date.civil(2008,2,1), "end" => Date.civil(2008,4,30)}, 
               "Y2Q1" => {"year" => "Y2", "quarter"=> "Q1", "start" => Date.civil(2008,5,1), "end" => Date.civil(2008,7,31)}, 
               "Y2Q2" => {"year" => "Y2", "quarter"=> "Q2", "start" => Date.civil(2008,8,1), "end" => Date.civil(2008,10,31) },
               "Y2Q3" => {"year" => "Y2", "quarter"=> "Q3", "start" => Date.civil(2008,11,1), "end" => Date.civil(2009,1,31) },
               "Y2Q4" => {"year" => "Y2", "quarter"=> "Q4", "start" => Date.civil(2009,2,1), "end" => Date.civil(2009,4,30) } }

    pis = ["Celniker","Henikoff","Karpen","Lai","Lieb","MacAlpine","Piano","Snyder","Waterston","White"]
    status = ["New","Uploaded","Validated","DBLoad","Track Config","Aprvl-PI","Aprvl-DCC","to GBrowser","to Modmine","to WB/FB"]
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
	all_distributions_by_pi[p.user.pi.split(",")[0]][status[step-1]] += 1  
	
	all_active_by_pi[p.user.pi.split(",")[0]][active_status[step-1]] += 1	unless step > active_status.length
	@all_active_by_status[active_status[step-1]][p.user.pi.split(",")[0]] += 1 unless step > active_status.length
    end



    @all_new_projects_per_group_per_quarter = Hash.new {|hash,quarter| hash[quarter] = Hash.new { |hash2, pi | hash2[pi] = 0} }
    # initialize to make sure all PIs are included; require each status to be represented
    pis.each {|p| quarters.each{|k,v| @all_new_projects_per_group_per_quarter[k][p] unless v["start"] > Time.now.to_date}}

    Project.all.each {|p| @all_new_projects_per_group_per_quarter[quarters.find {|k,v| p.created_at.to_date <= v["end"] && p.created_at.to_date >= v["start"]}[0]][p.user.pi.split(",")[0]] += 1 }


    @all_released_projects_per_group_per_quarter = Hash.new {|hash,quarter| hash[quarter] = Hash.new { |hash2, pi | hash2[pi] = 0} }
    # initialize to make sure all PIs are included; require each status to be represented
    pis.each {|p| quarters.each{|k,v| @all_released_projects_per_group_per_quarter[k][p] unless v["start"] > Time.now.to_date}}

    Project.all.find_all{|p| p.status=="released"}.each {|p| @all_released_projects_per_group_per_quarter[quarters.find {|k,v| p.created_at.to_date <= v["end"] && p.created_at.to_date >= v["start"]}[0]][p.user.pi.split(",")[0]] += 1 }


    @all_new_projects_per_quarter = Hash.new {|hash,quarter| hash[quarter] = 0} 
    Project.all.each {|p| @all_new_projects_per_quarter[quarters.find {|k,v| p.created_at.to_date <= v["end"] && p.created_at.to_date >= v["start"]}[0]] += 1 }


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
    status.each{|s| pis.each {|p| @all_projects_by_pi[p][s] = 0}}
    Project.all.each do |p|
          step = 0
          #identify what step its at
          step = case p.status
            when Project::Status::NEW : 1
            when Upload::Status::UPLOAD_FAILED : 1
            when Upload::Status::UPLOADED : 1
            when Validate::Status::VALIDATION_FAILED : 1
            when Expand::Status::EXPAND_FAILED : 1
            when Validate::Status::VALIDATED : 1
            when Load::Status::LOAD_FAILED : 1
            when Load::Status::LOADED : 1
            when 'tracks found' : 1
            when 'submitter approval' : 1
            when 'DCC approval' : 1
            when 'released to gbrowse' : 2
            when 'released to modmine' : 2
            when 'released' : 2
          else 1
          end
        @all_projects_by_pi[p.user.pi.split(",")[0]][status[step-1]] += 1
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
