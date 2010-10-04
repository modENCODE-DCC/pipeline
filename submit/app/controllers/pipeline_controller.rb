require 'find'
require 'digest/md5'
include Spawn
module ModPorter
  class UploadedFile
    def local_path
      @path
    end
  end
end
class PipelineController < ApplicationController

  # TODO: move some stuff into the private area so it can't be called by URL-hackers
  STANZA_OPTIONS = {
    'fgcolor' => TrackFinder::GD_COLORS,
    'bgcolor' => Hash[TrackFinder::GD_COLORS.map { |i| [i, i] }].merge({ 
        'sub { my $strand = shift->strand; if ($strand < 0) { return "indianred"; } elsif ($strand == 0) { return "lightsalmon"; } else { "gold" } }' => '[Color by strand]'
      }), 
    'group_on' => {
      '' => " [No grouping]", 
      'sub { return shift->name }' => "[Feature Name]",
      'sub { my @ts = shift->each_tag_value("Target"); foreach my $t (@ts) { $t =~ s/\s+\d+\s+\d+\s*$//g; return $t; } }' => "[Target Name]",
    },
    'stranded' => [ "0", "1" ],
    'key' => :text,
    'citation' => :citation_text,
    'label_transcripts' => {
      '' => " [No transcript label]",
      'sub { my $tag = shift->primary_tag; return ($tag eq "mRNA" || $tag eq "transcript") }'  => "[Show transcript label]",
    },
    'label' => {
      '' => " [No label]",
      'sub { return shift->name; }'                                              => "[Feature Name (for individual features)]", 
      'sub { return eval { [ eval { shift->get_SeqFeatures; } ]->[0]->name }; }' => "[Feature Name (for groups)]",
      'sub { return shift->display_name; }'                                      => "[Feature Display Name (for individual features)]", 
      'sub { return eval { [ eval { shift->get_SeqFeatures; } ]->[0]->display_name }; }' => "[Feature Display Name (for groups)]",
      'sub { my $f = shift; return unless scalar($f->get_SeqFeatures); my @ts = [$f->get_SeqFeatures]->[0]->each_tag_value("Target"); foreach my $t (@ts) { $t =~ s/\s+\d+\s+\d+\s*$//g; return $t; } }' => "[Target Name (for groups)]",
      'sub { my @ts = shift->each_tag_value("Target"); foreach my $t (@ts) { $t =~ s/\s+\d+\s+\d+\s*$//g; return $t; } }' => "[Target Name (for individual features)]",
      'sub { my ($type) = (shift->type =~ m/(.*):\d*/); return $type; }'         => "[Track Type]",
      'sub { return eval { shift->{"attributes"}->{"load_id"}->[0]; } }'         => "[GFF ID]", 
      'sub { return eval { shift->{"attributes"}->{"Note"}->[0]; } }'            => "[GFF Note]", 
      'sub { return shift->source; }'                                            => "[Submission #]",
    },
    'sort_order' => {
      '' => " [No sorting]",
      'sub ($$) {shift->feature->name cmp shift->feature->name}' => "[Feature Name]",
      'sub ($$) {shift->feature->source cmp shift->feature->source}' => "[Feature Source]",
    },
    'category' => [
      'Preview',
      'modENCODE tracks: Celniker Group',
      'modENCODE tracks: Henikoff Group',
      'modENCODE tracks: Karpen Group',
      'modENCODE tracks: Lai Group',
      'modENCODE tracks: Lieb Group',
      'modENCODE tracks: MacAlpine Group',
      'modENCODE tracks: Piano Group',
      'modENCODE tracks: Snyder Group',
      'modENCODE tracks: Waterston Group',
      'modENCODE tracks: White Group'
    ],
    'bump density' => :integer,
    'label density' => :integer,
    'glyph' => [
      'generic', 'segments', 'arrow', 'anchored_arrow', 'box', 'gene', 'CDS',
      'crossbox', 'dashed_line', 'diamond', 'dna', 'dot', 'dumbbell', 'ellipse' 'ex',
      'line', 'processed_transcript', 'primers', 'rainbow_gene', 'saw_teeth', 'span', 'splice_site',
      'translation', 'triangle' 'two_bolts', 'wave', 'wiggle_density', 'wiggle_xyplot'
    ],
    'connector' => [ 'solid', 'dashed', 'quill', 'none' ],
    'min_score' => :integer,
    'max_score' => :integer,
    'neg_color' => TrackFinder::GD_COLORS,
    'pos_color' => TrackFinder::GD_COLORS,
    'smoothing' => [ '', 'mean' ],
    'smoothing_window' => :integer,
    'bicolor_pivot' => {
      'zero' => 'zero',
      'mean' => 'mean',
      '' => '[avg of min/max]',
    },
    'maxdepth' => :integer,
    'show_mismatch' => [ "0", "1" ],
    'draw_target' => [ "0", "1" ],
    'height' => :integer,
  }

  before_filter :login_required, :except => [ :get_gbrowse_config ]
  before_filter :check_user_can_write, :except => 
        [
          :show,
          :new,
          :list,
          :view_my_queue,
          :status_table,
          :show_user,
	  :show_group,
          :deactivate_archive,
          :activate_archive,
          :command_status,
          :command_panel,
          :expand,
          :get_gbrowse_config,
          :publish
        ]

  before_filter :check_user_can_view, :except => 
        [
          :new,
          :list,
          :view_my_queue,
          :status_table,
          :show_user,
	  :show_group,
          :deactivate_archive,
          :activate_archive,
          :command_status,
          :expand ,
          :get_gbrowse_config
        ]

  def citation
    action_not_found
  end
  def edit
    begin
      @project = Project.find(params[:id])
      return false unless check_user_can_write @project
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

    if params[:commit] then
      old_project_type_id = @project.project_type_id
      if @project.update_attributes(params[:project]) then
        @project.status = Project::Status::UPLOADED
        @project.save
        redirect_to :action => 'show', :id => @project
      else
        flash[:error] = "Couldn't save project #{$!}."
      end
    end
  end

  def edit_lab_project
    begin
      @project = Project.find(params[:id])
      return false unless check_user_can_write @project
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

    pis = Hash.new
    if File.exists? "#{RAILS_ROOT}/config/PIs.yml" then
      pis = [ open("#{RAILS_ROOT}/config/PIs.yml") { |f| YAML.load(f.read) } ]
      pis = pis.first unless pis.nil?
    end
    pis = Hash.new if pis.nil?

    user_pis = pis[current_user.lab] ? current_user.lab : pis.find_all { |k, v| v.include?(current_user.lab) }.map { |k, v| k }

    unless current_user.is_a? Moderator then
      pis.delete_if { |k, v| !user_pis.include?(k) }
    end
    @acceptable_labs = pis.sort.map { |k, v| [ k.sub(/(, \S)\S*$/, '\1.'), v.sort.map { |vv| [ vv.sub(/(, \S)\S*$/, '\1.'), "#{k}/#{vv}"] } + [[ k.sub(/(, \S)\S*$/, '\1.'), "#{k}/#{k}"]] ] }

    if params[:commit] then
      # Update the project!
      (pi, lab) = params[:project_pi_and_lab].split("/")
      unless pis.to_a.flatten.include?(pi) && pis.to_a.flatten.include?(lab) then
        flash[:error] = "Invalid PI/Lab: #{pi}/#{lab}"
        redirect_to :action => "edit_lab_project", :id => @project.id
        return
      end
      @project.pi = pi
      @project.lab = lab
      if @project.save then
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

  def view_my_queue
    user_to_view = (params[:user_id] && User.find(params[:user_id]) && current_user.is_a?(Moderator)) ? User.find(params[:user_id]) : current_user
    @my_queued_commands = Project.find_all_by_user_id(user_to_view).map { |p| p.commands.find_all { |c| c.queued? } }.flatten.sort { |c1, c2| c1.queue_position <=> c2.queue_position }
    render :action => "view_my_queue", :layout => "popup"
  end

  def show_group
    if params[:pi] == "" then
      redirect_to :action => "list"
      return
    else
      if params[:pi] then
        session[:show_filter_pis] = params[:pi].map { |p| p == "" ? nil : p }.compact
      end
      session[:show_filter] = :group
      status
      render :action => "status"
    end
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
    @last_command_run = @project.commands.find_all { |cmd| ! cmd.queued? }.last
    @active_commands = @project.commands.all.find_all { |c| Project::Status::is_active_state(c.status) }.sort { |c1, c2| c1.queue_position <=> c2.queue_position }
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
    flash[:error] = "Admin killed command with ID #{params[:id]}"
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
    if (params[:moderator_assigned_id] && params[:moderator_assigned_id].to_i.to_s == params[:moderator_assigned_id]) then
      @project.write_attribute(:id, params[:moderator_assigned_id].to_i) unless Project.find_by_id(params[:moderator_assigned_id].to_i)
    end
    @projectTypes = getProjectTypes

    pis = Hash.new
    if File.exists? "#{RAILS_ROOT}/config/PIs.yml" then
      pis = [ open("#{RAILS_ROOT}/config/PIs.yml") { |f| YAML.load(f.read) } ]
      pis = pis.first unless pis.nil?
    end
    pis = Hash.new if pis.nil?

    user_pis = pis[current_user.lab] ? [ current_user.lab ] : pis.find_all { |k, v| v.include?(current_user.lab) }.map { |k, v| k }

    unless current_user.is_a? Moderator then
      pis.delete_if { |k, v| !user_pis.include?(k) }
    end
    @acceptable_labs = pis.sort.map { |k, v| [ k.sub(/(, \S)\S*$/, '\1.'), v.sort.map { |vv| [ vv.sub(/(, \S)\S*$/, '\1.'), "#{k}/#{vv}"] } + [[ k.sub(/(, \S)\S*$/, '\1.'), "#{k}/#{k}"]] ] }

    if params[:commit] then
      @project.user_id = current_user.id 
      @project.status = Project::Status::NEW

      (pi, lab) = params[:project_pi_and_lab].split("/")
      unless pis.to_a.flatten.include?(pi) && pis.to_a.flatten.include?(lab) then
        flash[:error] = "Invalid PI/Lab: #{pi}/#{lab}"
        return
      end
      @project.pi = pi
      @project.lab = lab

      if @project.save
        redirect_to :action => 'upload', :id => @project.id
        log_project_status
      end
    end
    #render :action => Project::Status::NEW
  end

  # add_experiment_prop:
  # for adding properties to an existing experiment
  def add_experiment_prop
    begin
      @project = Project.find(params[:id])
      return false unless ((check_user_can_write @project) or (@project.status == Project::Status::RELEASED))
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
    end

    loading_ok = Project::Status::ok_next_states(@project).include?(Project::Status::LOADING)
    is_released =  (@project.status == Project::Status::RELEASED)
    unless (loading_ok || is_released) then
      flash[:error] = "Whoops! Project must have generated a ChadoXML file to apply a patch."
      redirect_to :action => "show", :id => @project
      return
    end

    xml_path = File.join(path_to_project_dir(@project), "extracted")


    # Construct the menus for selecting the params ---
    props = AddExperimentProp.find_all_by_project_id(@project.id).last

    # Generate controller to get patch files
    if props.nil? then
      add_exp_prop_controller = AddExperimentPropController.new(:project => @project, :user_id => current_user.id, :xml_path => xml_path)
    else
      add_exp_prop_controller = AddExperimentPropController.new(:command => props)
    end

    if props.nil? then
      # Oh no, no properties, start lookin'!
      @xml_is_parsed = false  
      spawn do
        add_exp_prop_controller.run
      end
      @all_experiments = []
      @all_dbxrefs = []
      @all_cvterms = []
      flash[:notice] = "Please wait while parsing the ChadoXML file."
    elsif props.status != AddExperimentProp::Status::PARSED then
      # Still processing
      @xml_is_parsed = false
      @all_experiments = []
      @all_dbxrefs = []
      @all_cvterms = []
      flash[:notice] = "Please wait while parsing the ChadoXML file."
    else
      flash[:notice] = nil
      @all_experiments = props.get_experiments
      @all_dbxrefs = props.get_dbxrefs
      @all_cvterms = props.get_cvterms
      @xml_is_parsed = true  
    end

    case params[:commit]
      when "Create new property"
        add_exp_prop_controller.make_patch_file(params)
      when "Apply changes"
        logger.info add_exp_prop_controller.insertDB_and_delete(params)
      when "Cancel"
        ""
      else
        ""
    end

    @pending_patches =  add_exp_prop_controller.get_patches
    @applied_patches = add_exp_prop_controller.get_props_in_master
  
  end # end add_experiment_prop

  # Activates command chaining for the current project and queues
  # all remaining commands in order
  def chain_commands
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    # Run the chaining -- if it returns false, don't give the 
    # "queued successfully" message
    err = do_chain_commands(@project)
    if err.nil? then
      flash[:notice] = "Your commands have been queued and you will be emailed when they are complete or have failed."
    else # do_chain_commands returned, but false!
      flash[:error] = err
    end

    redirect_to  :action => "show", :id => @project
  end
  
  # Queues up all remaining commands in project
  # and start the next command in the queue 
  def do_chain_commands(project)
    last_cmd = project.last_command_not_failed
    return "There are no previous commands for this project, and so no uploaded files could be found!" if last_cmd.nil?
    if last_cmd.is_a?(Upload) || last_cmd.is_a?(Expand) then
      # Upload will automatically run expand, and insert it right after the upload
      do_validate(project, :defer => true)
      do_load(project, :defer => true)
      do_find_tracks(project)
    elsif last_cmd.is_a?(Validate) then
      do_load(project, :defer => true)
      do_find_tracks(project)
    elsif last_cmd.is_a?(Load) then
      do_find_tracks(project)
    else
      return "It's not possible to chain commands after a #{last_cmd.class.name}"
    end
    return nil
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

    if !@project.has_readme? && !@project.has_metadata? then
      flash[:error] = "" if flash[:error].nil?
      error_msg = "This project has no README or IDF/SDRF and will not be displayed on the downloads page!<br/>Fix this now by <a href=\"" + url_for(:action => :upload_replacement, :id => @project, :replace => "README") + "\">uploading a README</a>."
      unless flash[:error].end_with?(error_msg) then
        flash[:error] += "<br/>" unless flash[:error] == ""
        flash[:error] += error_msg
      end
    end


    @last_command_run = @project.commands.find_all { |cmd| ! cmd.queued? }.last
    @num_active_archives = @project.project_archives.find_all { |pa| pa.is_active }.size
    @num_archives = @project.project_archives.size

    @active_commands = @project.commands.all.find_all { |c| Project::Status::is_active_state(c.status) }.sort { |c1, c2| c1.queue_position <=> c2.queue_position }
    @active_command = @active_commands.find { |c| c.project_id = @project.id }

    @user_can_write = check_user_can_write @project, :skip_redirect => true
    @user_is_owner = check_user_is_owner @project

    if params[:new_comment] && @user_can_write then
      @project.comments.new(:comment => params[:new_comment], :user => current_user).save
      redirect_to :action => :show, :id => @project
      return
    end

    @comments = @project.comments.find(:all, :order => :created_at).reverse

    # GBrowse link if available
    ts = nil
    if Project::Status::ok_next_states(@project).include?(Project::Status::AWAITING_RELEASE) then
      ts = TrackStanza.find_by_project_id_and_released(@project.id, true)
    else
      ts = TrackStanza.find_by_project_id_and_user_id(@project.id, current_user.id)
    end
    if ts && ts.stanza && ts.stanza.values.size > 0 then
      organism = ts.stanza.values.first[:organism]
      if organism == "Caenorhabditis elegans" then
        @gbrowse_url = "/gbrowse/cgi-bin/gbrowse/modencode_wormbase/?name=3L:6066513..6266513;grid=1;label=_scale-_scale:overview-_scale:region"
      else
        @gbrowse_url = "/gbrowse/cgi-bin/gbrowse/modencode_flybase/?name=III:4200000..4300000;grid=1;label=_scale-_scale:overview-_scale:region"
      end
      @gbrowse_url += "-" + ts.stanza.keys.join("-")
    end

    if Project::Status::ok_next_states(@project).include?(Project::Status::AWAITING_RELEASE) then
      flash[:warning] = "This project is awaiting release and approval!"
    end
    if @project.deprecated? then
      flash[:error] = "" if flash[:error].nil?
      flash[:error] += "<br/>" unless flash[:error] == ""
      if !@project.retracted? then
        flash[:error] += "This project has been deprecated by project #{@project.deprecated_project_id}!"
      else
        flash[:error] += "This project has been retracted with no replacement!"
      end
    end
    if @project.superseded? then
      flash[:notice] = "" if flash[:notice].nil?
      flash[:notice] += "<br/>" unless flash[:notice] == ""
      flash[:notice] += "This project has been superseded by project #{@project.superseded_project_id}."
    end
    
    # Check for duplicates
    @signatures = get_matching_files( @project )

    # Set up a notice if there are any collisions
    unless @signatures.empty? then
      cookieVal = cookies[:modencode_dupes] ? cookies[:modencode_dupes].split(",") : []
      unless ( cookieVal.include? params[:id].to_s ) then
        # Hide the whole notice div unless there's another notice in it
        # In which case only hide the dupe_msg inner div
        unique_divid = "dupe_msg" + (0..8).map { |x| ('a'..'z' ).to_a[rand(26)] }.join
        old_message = flash[:notice].nil? ? "" : flash[:notice]
        (old_message.empty?) ? divToHide = "notice" : divToHide = unique_divid
        # This ajax request calls set_file_dupe_cookie to create the cookie,
        # then runs the JS function hideDupeNotice on the show page to 
        # hide the notice from this refresh.
        dupe_ajax = "<a href=\"#\" onClick=\"new Ajax.Request(" +
        "'/submit/pipeline/set_file_dupe_cookie/#{@project.id}', " +
        "{asynchronous:true, evalScripts:true, onComplete:function(request)"+
        "{hideDupeNotice('#{divToHide}')}}); return false;\">[X]</a>"
        # Change mesesage based on whether the dupes are in this project or another project.
        has_matches_this_other_proj = [false, false] # 1st = this, 2nd = other
        @signatures.each{|k, matched_files|
          matched_files.each{|pid, file|
            which_match = pid == @project.id ? 0 : 1
            has_matches_this_other_proj[which_match] = true
            break if ( has_matches_this_other_proj[0] && has_matches_this_other_proj[1])
          }
        }
        this_or_other = case has_matches_this_other_proj 
                          when [true, true]
                            "this and other"
                          when [true, false]
                            "this"
                          when [false, true]
                            "other"
                          else
                            "this shouldn't happen"
                          end

        dupe_msg = "<div id=\"#{unique_divid}\">Some files or archives in this "+
        "project have duplicates in #{this_or_other} project#{
          has_matches_this_other_proj[1] ? "s" : "" }! See Uploaded Data below " +
        "for details. #{dupe_ajax}</div>"

        flash.now[:notice] = old_message + ((old_message.empty?) ? "" : "<br/>") + dupe_msg
      end
    end
  end


  # Adds the current project's ID to the list of projects being
  # ignored in the cookie. If called with remove=true will instead
  # remove that ID, so the message will again be shown.
  def set_file_dupe_cookie
    cookie_str = cookies[:modencode_dupes]
    if cookie_str.nil? then cookie_str = ""  end
    projects_ignoring_dupes = cookie_str.split(",")
    
    if params[:remove] then
      projects_ignoring_dupes.delete(params[:id])
    else
      projects_ignoring_dupes.push(params[:id].to_s)
    end
    cookies[:modencode_dupes] = {:value => projects_ignoring_dupes.join(","), 
      :expires => 10.years.from_now }
  end

  # Returns all ProjectFiles and ProjectArchives whose signatures match those
  # of the PF and PA in the passed project.
  # Output: Hash : Keys are archives and files in this project
  # For key PA, value is an array:
  #   Each entry of the array is a 2-element array consisting
  #   of a PA / PF that matched the signature of the PA (2nd element)
  #   and it's project-id (first element)
  #
  def get_matching_files(proj)
    dupes_found = {}
    archive_sigs_to_check = []
    file_sigs_to_check = []
    files_this_project = []
    proj.project_archives.each{|pa|
      archive_sigs_to_check.push pa.signature
      pa.project_files.each{|pf|
        file_sigs_to_check.push pf.signature
        files_this_project.push pf # while we're at it -- will need later
      }
    }
    # uniquify and remove nil sigs
    archive_sigs_to_check = archive_sigs_to_check.uniq.reject{|la| la.nil?}
    file_sigs_to_check = file_sigs_to_check.uniq.reject{|la| la.nil?}
   
    # Check signatures
    archive_match = ProjectArchive.find_all_by_signature(archive_sigs_to_check)
    file_match = ProjectFile.find_all_by_signature(file_sigs_to_check)


    # Then, construct the hash. Go through the PA and PF again and match
    # Them up to sigs
    archive_match.each{|am|
      # Make the mini-array - separate out the Project
      archive_value = [am.project_id, am]
      # Find all archives in this project that match by signature
      proj.project_archives.find_all_by_signature(am.signature).each{|pa|
        # if am and pa are the same, skip it ; otherwise add even if
        # they're in the same project
        next if am.id == pa.id
        dupes_found[pa] = [] unless dupes_found[pa]
        dupes_found[pa].push archive_value
      }
    }
    
    file_match.each{|fm|
      # Make the mini-array - separate out the Project
      fmpa = fm.project_archive
      fmpap = fmpa.project unless fmpa.nil?
      fmpapid = fmpap.id unless fmpap.nil?
      next if fmpapid.nil? # If it doesn't have a project, just skip it
      file_value = [fmpapid, fm]
      # Find all files in this project that match by signature
      files_this_project.each{|ftp|
        if ftp.signature == fm.signature then
          # skip it if they're the same file
          next if ftp.id == fm.id
          dupes_found[ftp] = [] unless dupes_found[ftp]
          dupes_found[ftp].push file_value
        end
      }
    }
    dupes_found
  end

  def dupe_file_info
    @project = Project.find(params[:id])
    @signatures = get_matching_files( @project )
    render :action => "dupe_file_info", :layout => "popup"
  end


  def download_chadoxml
    @autoRefresh = false
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
    if (@project.status != Expand::Status::EXPANDED)
      # Don't bother re-expanding if the last status was a successful expand
      queue_reexpand_project(@project)
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

    # Also need to delete everything in the extracted dir since it's no longer up-to-date
    ExpandController.remove_extracted_folder(project_archive) unless project_archive.nil?

    # Clean up any expanded archives
    @project.project_archives.each do |pa| 
      pa.status = ProjectArchive::Status::NOT_EXPANDED
      pa.save
      pa.project_files.each do |pf|
        pf.destroy
      end
    end

    # Rexpand any active archives prior to this one
    do_expand(project_archive)
 
    redirect_to :action => 'show', :id => @project
  end

  def upload_replacement
    begin
      @project = Project.find(params[:id])
      return false unless check_user_can_write @project
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    # Handle inserting a README when none existed before
    if params[:replace] == "README" then
      # Make a new archive
      (@project_archive = @project.project_archives.new).save
      @project_archive.file_name = "#{"%03d" % @project_archive.attributes[@project_archive.position_column]}_README.tgz"
      @project_archive.file_date = Time.now
      @project_archive.is_active = true
      @project_archive.save

      @file = @project_archive.project_files.new
      @file.file_name = "README"
      @file.file_size = 0
      @file.file_date = Time.now
      @file.save
      @replace_id = "README"
      @replace_file_name = @file.file_name

      unless request.post?
        render
        @file.destroy
        @project_archive.destroy
        return
      else
        @file.destroy
        @project_archive.destroy
      end

    else
      begin
        @file = ProjectFile.find(params[:replace])
        return false if @file.project_archive.nil?
        return false unless @file.project_archive.project == @project
      rescue
        flash[:error] = "Couldn't find project file with ID #{params[:replace]} attached to project #{@project.id}"
        redirect_to :action => "show", :id => @project
        return
      end

      @project_archive = @file.project_archive
      @replace_id = @file.id
      @replace_file_name = @file.file_name
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
    upurl = "" if upurl.nil? or upurl == "http://" # If it's the default value, ignore it

    # If nothing was submitted, return
    if upfile.blank? && upurl.blank? then
      flash[:warning] = "No file submitted. Please upload a file to continue."
      return 
    end

    if !upurl.blank? then
      # Use a URL
      filename = sanitize_filename(upurl)
    else # !upfile.blank?
      # Use a file uploaded through the browser
      filename = sanitize_filename(upfile.original_filename)
    end

    # Filename must equal name of file we're replacing
    if filename != sanitize_filename(@file.file_name) then
      flash[:error] = "Filename of file being uploaded (#{filename}) does not match file being replaced (#{File.basename(@file.file_name)})."
      return
    end

    redirect_to :action => 'show', :id => @project

    # Upload in background
    do_upload_replacement(@replace_file_name, upurl, upfile, upcomment, filename)
  end

  def do_upload_replacement(replace_file_name, upurl, upfile, upcomment, filename)
    # The trick here is that we turn the file into an archive so it gets
    # tracked properly by the system

    # Create a ProjectArchive to handle the upload
    (project_archive = @project.project_archives.new).save # So we get an archive_no
    # Note the ".tgz" on the filename; we're about to create an archive of this single file
    project_archive.file_name = "#{"%03d" % project_archive.attributes[project_archive.position_column]}_#{filename}.tgz"
    project_archive.file_date = Time.now
    project_archive.is_active = false
    project_archive.comment = upcomment
    project_archive.save

    # Need to put the file somewhere, might as well overwrite the current one in the extracted dir
    # This gives us an easy way to make the new tarball with the full path intact, too
    File.unlink(File.join(path_to_project_dir(@project), "extracted", replace_file_name)) if File.exists?(File.join(path_to_project_dir(@project), "extracted", replace_file_name))
    FileUtils.mkpath(File.dirname(File.join(path_to_project_dir(@project), "extracted", replace_file_name))) unless File.exists?(File.dirname(File.join(path_to_project_dir(@project), "extracted", replace_file_name)))

    if !upurl.blank? || upurl == "http://" then
      # Uploading from a remote URL; use open-uri (http://www.ruby-doc.org/stdlib/libdoc/open-uri/rdoc/)
      projectDir = path_to_project_dir(@project)

      upload_controller = UrlUploadReplacementController.new(:source => upurl, :filename => File.join(path_to_project_dir(@project), "extracted", replace_file_name), :project => @project, :archive_name => project_archive.file_name)
      upload_controller.timeout = 36000 # 10 hours

      # Queue upload command
      upload_controller.queue(:user => current_user)
    else
      # Uploading from the browser
      destfile = File.join(path_to_project_dir(@project), "extracted", replace_file_name)
      if !upfile.local_path
        File.open(destfile, "wb") { |f| f.write(upfile.read) }
        upload_controller = FileUploadReplacementController.new(:source => destfile, :filename => destfile, :project => @project, :archive_name => project_archive.file_name)
        upload_controller.timeout = 20 # 20 seconds
        upload_controller.command_object.stderr = "Intentionally placeholdering to #{destfile}\n"
      else
        upload_controller = FileUploadReplacementController.new(:source => upfile.local_path, :filename => destfile, :project => @project, :archive_name => project_archive.file_name)
        upload_controller.timeout = 600 # 10 minutes
      end

      # Immediately run upload command
      # (Since this was uploaded from a browser, need to copy the file before the tmp file dissapears)
      upload_controller.command_object.user = current_user
      upload_controller.command_object.save
      upload_controller.run

      # Rexpand all active archives for this project
      queue_reexpand_project(@project)
      CommandController.do_queued_commands
    end

  end

  def upload
    begin
      @project = Project.find(params[:id])
      return false unless check_user_can_write @project
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    @user = current_user

    extensions = ["zip", "ZIP", "tar.gz", "TAR.GZ", "tar.bz2", "TAR.BZ2", "tgz", "TGZ"]

    # handle FTP stuff
    @use_ftp = (ActiveRecord::Base.configurations[RAILS_ENV]['ftpUrl'].nil? ? false : true)
    @ftpMount = ActiveRecord::Base.configurations[RAILS_ENV]['ftpMount']
    @ftpUrl = ActiveRecord::Base.configurations[RAILS_ENV]['ftpUrl']
    @use_ftp = !@ftpMount.nil?
    if File.exists? "#{RAILS_ROOT}/config/database.yml" then
      # Re-read FTP config on the fly
      open("#{RAILS_ROOT}/config/database.yml") { |f| YAML.load(f.read) }.each_pair { |name, definition|
        @use_ftp = true if (name == "ftpUrl" && !definition.nil?)
        @ftpMount = definition if name == "ftpMount"
        @ftpUrl = definition if name == "ftpUrl"
      }
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
    upftp = params[:upload_ftp]
    uprsync = params[:upload_rsync]
    upurl = "" if upurl.nil? or upurl == "http://" # If it's the default value, ignore it
    upftp = "" unless upftp # Don't let upftp be nil
    uprsync = "" if uprsync.nil? or uprsync =="rsync://" # Ignore default value
 

    # If nothing was submitted, return
    if upfile.blank? && upurl.blank? && upftp.blank? && uprsync.blank? then
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
    elsif !uprsync.blank? then
      # Use a file uploaded through rsync
      filename = sanitize_filename(uprsync)
    else # !upfile.blank?
      # Use a file uploaded through the browser
      filename = sanitize_filename(upfile.original_filename)
    end
    # Validate content type (browser upload) or extension (other uploads)
    extensionsByMIME = {
          "application/zip" => ["zip", "ZIP"],
          "application/x-tar" => ["tar.gz", "TAR.GZ", "tar.bz2", "TAR.BZ2", "tgz", "TGZ"],
          "application/x-compressed-tar" => ["tar.gz", "TAR.GZ", "tar.bz2", "TAR.BZ2", "tgz", "TGZ"],
          "application/x-compressed" => ["tar.gz", "TAR.GZ", "tgz", "TGZ"],
          "application/x-tar" => ["tar.gz", "TAR.GZ", "tar.bz2", "TAR.BZ2", "tgz", "TGZ"],
          "application/x-tar-gz" => ["tar.gz", "TAR.GZ", "tgz", "TGZ"],
          "application/octet-stream" => ["tar.gz", "TAR.GZ", "tar.bz2", "TAR.BZ2", "tgz", "TGZ"],
          "application/gzip" => ["tar.gz", "TAR.GZ", "tgz", "TGZ"],
          "application/x-gzip" => ["tar.gz", "TAR.GZ", "tgz", "TGZ"],
          "application/x-gtar" => ["tar.gz", "TAR.GZ", "tgz", "TGZ"]
    }
    # If it's a browser upload, check content type unless we're skipping the check
    if (!upfile.blank?) and (params["skip_content_check"] != "yes") then 
      extensions = extensionsByMIME[upfile.content_type.chomp]
    else # Otherwise, either it's a different upload type OR we're skipping content check 
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

    # Create a directory for putting the uploaded file into
    # TODO: Are these two lines necessary?
    projectDir = File.dirname(path_to_file(filename))
    Dir.mkdir(projectDir,0775) unless File.exists?(projectDir)
   

    chain_after_upload = params[:chain_after_upload]
    
    # If we're not chaining, redirect and queue the upload
    unless chain_after_upload == "do_chain" then
      redirect_to :action => 'show', :id => @project
    
      # Upload in background
      do_upload(upurl, upftp, upfile, uprsync, 
                upcomment, filename)
    else # we _are_ chaining -- queue upload, then queue remaining commands
      do_upload(upurl, upftp, upfile, uprsync, 
                upcomment, filename)
    
      chain_commands  #(:id =>@project) 
    end
  end

  def deactivate_archive
    project_archive = ProjectArchive.find(params[:id])
    @project = project_archive.project
    return false unless check_user_can_write @project

    do_deactivate_archive(project_archive)

    # Rexpand all active archives for this project
    queue_reexpand_project(@project)
    CommandController.do_queued_commands

    redirect_to :action => 'show', :id => @project
  end

  def activate_archive
    project_archive = ProjectArchive.find(params[:id])
    @project = project_archive.project
    return false unless check_user_can_write @project

    do_activate_archive(project_archive)

    # Rexpand all active archives for this project
    queue_reexpand_project(@project)
    CommandController.do_queued_commands

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

    # Rexpand all active archives for this project
    queue_reexpand_project(@project)
    CommandController.do_queued_commands

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

    # Rexpand all active archives for this project
    queue_reexpand_project(@project)
    CommandController.do_queued_commands

    redirect_to :action => 'show', :id => @project
  end

  def _load # should be def load, but Rails uses that function name already
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

    redirect_to :action => 'show', :id => @project
  end 

  def build_report
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

    unless Project::Status::ok_next_states(@project).include?(Project::Status::REPORTING) then
      redirect_to :action => :show, :id => @project
      return false
    end

    do_report(@project)

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

    options[:user] = current_user
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
      redirect_to :action => :show, :id => @project
      return false
    end

    do_find_tracks(@project)
    redirect_to :action => :show, :id => @project
  end

  def find_tracks_fast
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    unless Project::Status::ok_next_states(@project).include?(Project::Status::FINDING) then
      redirect_to :action => :show, :id => @project
      return false
    end

    do_find_tracks_fast(@project)

    redirect_to :action => :show, :id => @project
  end

  def preview
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    unless Project::Status::ok_next_states(@project).include?(Project::Status::GENERATING_PREVIEW) then
      redirect_to :action => :show, :id => @project
      return false
    end

    do_preview(@project)

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
      # Redirect here so that hitting refresh in the browser doesn't prompt annoyingly
      unless params[:override] && current_user.is_a?(Moderator) then
        redirect_to :action => :show, :id => @project
        return false
      end
    end
    if params[:organism] then
      case params[:organism]
      when "Caenorhabditis elegans"
      when "Drosophila pseudoobscura pseudoobscura"
      when "Drosophila simulans"
      when "Drosophila sechellia"
      when "Drosophila persimilis"
      when "Drosophila mojavensis"
      else
        params[:organism] = "Drosophila melanogaster"
      end
      TrackStanza.find_all_by_project_id_and_user_id(@project.id, current_user.id).each { |ts|
        stanza = ts.stanza
        stanza.each { |track, config| config[:organism] = params[:organism] }
        ts.stanza = stanza
        ts.save
      }
      # Unaccept config(s) for this project if any have been accepted
      TrackStanza.find_all_by_project_id(@project.id).each { |ts|
        ts.released = false
        ts.save
      }
    end

    if params[:delete_semantic_stanza] then
      if @project.status == Project::Status::CONFIGURED then
        @project.status = Project::Status::FOUND
        @project.save
      end

      # Unaccept config(s) for this project if any have been accepted
      TrackStanza.find_all_by_project_id(@project.id).each { |ts|
        ts.released = false
        ts.save
      }

      ts = TrackStanza.find_by_project_id_and_user_id(@project.id, current_user.id)
      stanza = ts.stanza
      stanza[params[:delete_semantic_stanza]][:semantic_zoom] = Array.new unless stanza[params[:delete_semantic_stanza]].nil?
      ts.stanza = stanza
      ts.save
      redirect_to :action => :configure_tracks, :id => @project
      return
    end

    if params[:delete_stanza] then
      if @project.status == Project::Status::CONFIGURED then
        @project.status = Project::Status::FOUND
        @project.save
      end

      # Unaccept config(s) for this project if any have been accepted
      TrackStanza.find_all_by_project_id(@project.id).each { |ts|
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
      TrackStanza.find_all_by_project_id(@project.id).each { |ts|
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
      unless (session[:generating_track_stanza]) then
        session[:generating_track_stanza] = @project.id
        session[:generating_track_stanza_error] = nil
        spawn do
          require 'timeout'
          status = nil
          track_defs = nil
          begin
          status = Timeout::timeout(600) {
            logger.info "Starting GBrowse config generation"
            track_defs = TrackFinder.new.generate_gbrowse_conf(@project.id)
            logger.info "Done with GBrowse config generation"
          }
          rescue Exception => e
            logger.error "Failed to generate config (timeout?) - rescued #{e.inspect}"
            session[:generating_track_stanza_error] = "Unable to generate config (timeout?)"
          end
          # Delete old one
          TrackStanza.destroy_all(:user_id => current_user.id, :project_id => @project.id)
          ts = TrackStanza.new :user_id => current_user.id, :project_id => @project.id
          ts.stanza = track_defs
          ts.save
          # Unaccept config(s) for this project if any have been accepted
          TrackStanza.find_all_by_project_id(@project.id).each { |ts|
            ts.released = false
            ts.save
          }
          session[:generating_track_stanza] = nil
          session.close
        end
        session.close
        redirect_to :action => :configure_tracks, :id => @project
      end
    else
      @ts_user = ts.user
      @track_defs = ts.stanza
    end


    @track_defs = Hash.new if @track_defs.nil?
    if @track_defs.values.first && @track_defs.values.first[:organism].nil? then
      @organism = "Drosophila melanogaster"
      @track_defs.each { |track, config| config[:organism] = "Drosophila melanogaster" }
      ts.stanza = @track_defs
      ts.save
    end
    @organism = @track_defs.values.first[:organism] if @track_defs.values.first
    
    @stanza_options = STANZA_OPTIONS
  end
      
  def configure_geo
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    unless @project.report_generated? then
      redirect_to :action => :show, :id => @project
      return false
    end
    if @project.report_tarball_generated? then
      flash[:notice] = "GEO tarball already generated, you must rebuild if you want to edit."
    end
    @report_command = @project.commands.all.find_all { |cmd| cmd.is_a?(Report) && cmd.succeeded? }.sort { |up1, up2| up1.end_time <=> up2.end_time }.last
    geo_dir = @report_command.command.split(" ")[2]
    if !File.exists?(geo_dir) then
      flash[:error] = "Can't find a GEO package; please regenerate the GEO report"
      redirect_to :action => :show, :id => @project
      return
    end


    if params[:commit_to_tarball] then
      soft_filename = File.join(geo_dir, "modencode_#{@project.id}.soft")
      tarball = File.join(geo_dir, "modencode_#{@project.id}.tar")
      run_command = "tar Af \"#{tarball}\" \"#{soft_filename}\" 2>&1"
      (reporter, command_params, package_dir, make_tarball) = @report_command.command.split(/ /)
      make_tarball = "1"
      @report_command.command = [reporter, command_params, package_dir, make_tarball].join(" ")
      @report_command.save
      @report_command.controller.queue
      redirect_to :action => :show, :id => @project
      return
    end

    if params[:send_to_geo] then
      tarball = File.join(geo_dir, "modencode_#{@project.id}.tar")
      (reporter, command_params, package_dir, make_tarball, send_to_geo) = @report_command.command.split(/ /)
      send_to_geo = "1"
      @report_command.command = [reporter, command_params, package_dir, make_tarball, send_to_geo].join(" ")
      @report_command.save
      @report_command.controller.queue
      redirect_to :action => :show, :id => @project
      return false
    end

    @listing = Array.new
    Find.find(geo_dir) do |path|
      next if File.basename(path) == File.basename(geo_dir)
      relative_path = path[geo_dir.length..-1]
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
  end

  def edit_soft
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    unless @project.report_generated? then
      redirect_to :action => :show, :id => @project
      return false
    end
    @report_command = @project.commands.all.find_all { |cmd| cmd.is_a?(Report) && cmd.succeeded? }.sort { |up1, up2| up1.end_time <=> up2.end_time }.last
    geo_dir = @report_command.command.split(" ")[2]
    unless File.exists?(File.join(geo_dir, "modencode_#{@project.id}.soft")) then
      redirect_to :action => :configure_geo, :id => @project
    end
    soft_filename = File.join(geo_dir, "modencode_#{@project.id}.soft")

    if params[:commit] then
      # Trying to update
      new_lines_hash = params[:line]
      new_lines = Array.new
      new_lines_hash.each_pair { |k, v|
        new_lines[k.to_i] = "#{v["0"]} = #{v["1"]}"
      }
      require 'pp'
      File.open(soft_filename, "w") do |f|
        new_lines.each { |l| l.sub!(/\s*$/, '') }
        f.puts new_lines.join("\n")
      end
      redirect_to :action => :edit_soft, :id => @project.id
      return
    end
    
    @lines = Array.new
    File.open(soft_filename) do |f|
      @lines = f.lines.reject { |line| line =~ /^\s*$/ }.map { |line| line.split(" = ") }
    end

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

    update_errors = Array.new

    # Copy current accepted config over to this user's config if they want 
    # that to happen
    if params[:copy_accepted] && params[:copy_accepted] == "true" then
      accepted_config = TrackStanza.find_by_project_id_and_released(@project.id, true)
      unless accepted_config.nil? then
        user_config = TrackStanza.find_by_project_id_and_user_id(@project.id, current_user.id)
        if user_config.nil? then
          user_config = TrackStanza.new :user_id => current_user.id, :project_id => @project.id
        end
        user_config.stanza = accepted_config.stanza
        user_config.save
      end
    end

    # Unaccept config(s) for this project if any have been accepted
    TrackStanza.find_all_by_project_id(@project.id).each { |ts|
      ts.released = false
      ts.save
    }

    changed = false
    if params[:old_project_id] && params[:do] == "copy" then
      res = copy_stanza(current_user.id, params[:old_project_id].to_i, @project.id)
      if (res != true) then
        update_errors.push res
      end
    else
      stanzaname = params[:stanzaname]
      user_stanzas = TrackStanza.find_all_by_user_id_and_project_id(current_user.id, @project.id)
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

        if stanzas[stanzaname][:unique_analyses] && option == "bgcolor" then
          n = 0
          color_mappings = Hash[ stanzas[stanzaname][:unique_analyses].map { |a| v = [a, TrackFinder::GD_COLORS[n%TrackFinder::GD_COLORS.size]]; n += 1; v} ]
          default_color = "lightgrey"
          sub =  "sub { my @as = shift->each_tag_value(\"analysis\"); return '#{default_color}' unless scalar(@as);"
          color_mappings.each_pair { |analysis, color|
            sub += "  return '#{color}' if '#{analysis}' eq $as[0];"
          }
          sub += "  return '#{default_color}'; }"
          values[sub] = "[Color By Analysis]"
        end 

        okay_value = false
        if values.is_a? Array then
          okay_value = true if values.member?(value)
        elsif values.is_a? Hash then
          okay_value = true if values.keys.member?(value)
        elsif values.is_a? Symbol then
          # Controlled type
          case values
          when :integer
            okay_value = true if value.to_i.to_s == value.to_s
          when :text
            okay_value = true if value =~ /^[a-zA-Z0-9_ :-]*$/
          when :citation_text
            okay_value = true
            begin
              REXML::Document.new("<html>#{value.gsub(/&/, '&amp;')}</html>")
            rescue REXML::ParseException => e
              update_errors.push "Citation text is not valid XML. #{e}"
              okay_value = false
            end
          end
        end

        if okay_value then
          if (stanzas[stanzaname][option] != value) then
            stanzas[stanzaname][option] = value
            changed = true
          end
        elsif !value.nil? && value.length > 0 then
          update_errors.push "#{value} is not okay for #{option}"
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
            elsif values.is_a? Hash then
              okay_value = true if values.keys.member?(value)
            elsif values.is_a? Symbol then
              # Controlled type
              case values
              when :integer
                okay_value = true if value.to_i.to_s == value.to_s
              when :text
                okay_value = true if value =~ /^[a-zA-Z0-9_ -]*$/
              when :citation_text
                okay_value = true
                begin
                  REXML::Document.new("<html>#{value}</html>")
                rescue
                  update_errors.push "Citation text is not valid XML."
                  okay_value = false
                end
              end
            end

            if okay_value then
              if (stanzas[stanzaname][:semantic_zoom][zoom_level][option] != value) then
                stanzas[stanzaname][:semantic_zoom][zoom_level][option] = value
                changed = true
              end
            else
              update_errors.push "#{value} is not okay for #{option}"
            end
          end
        end
        if params["zoom:#{zoom_level}"].to_i.to_s == params["zoom:#{zoom_level}"].to_s then
          new_zoom_level = params["zoom:#{zoom_level}"].to_i
          if new_zoom_level != zoom_level then
            # Trying to change the actual zoom_level
            stanzas[stanzaname][:semantic_zoom][new_zoom_level] = stanzas[stanzaname][:semantic_zoom][zoom_level]
            stanzas[stanzaname][:semantic_zoom].delete(zoom_level)
            user_stanza.stanza = stanzas
            user_stanza.save

            # We should go ahead and force a refresh since this changes lots of underlying form fields
            headers["Content-Type"] = "application/javascript"
            render :text => "location.replace('#{url_for({ :action => :configure_tracks, :id => params[:id] })}')"
            return
          end
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
      if params[:reload] then
        render :text => "window.location.reload();"
      else
        render :text => "
          Controller.update_coordinates(
            '#{stanzaname}', 'name:#{name}', '#{chr}', #{fmin}, #{fmax}
          );
        "
      end
      return
    end

    headers["Content-Type"] = "text/javascript"
    if params[:reload] then
      response = "window.location.reload();"
      if update_errors.size > 0 then
        response = "alert('#{update_errors.map { |ue| ue.gsub(/\n/, "\\n") }.join('\n').gsub(/'/, "\\\\'")}');" + response
      end
      render :text => response
    else
      response = "1;"
      if update_errors.size > 0 then
        response = "alert('#{update_errors.map { |ue| ue.gsub(/\n/, "\\n") }.join('\n').gsub("'", "\\'")}');"
      end
      render :text => response
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

    @checklist_for_release_by_pi = {
      "01General Items" => [
        [ "Appropriate experiment title?", { :controller => :public, :action => :citation, :id => @project }, "View Citation..." ],
        [ "GEO/SRA IDs okay?", { :controller => :curation, :action => :geo_sra_ids, :id => @project }, "View GEO and SRA IDs..." ],
        [ "Experiment description link okay?", { :controller => :curation, :action => :experiment_description, :id => @project }, "View Experiment Description..." ],
        [ "If a replicate submission, does it replace the old one?", false ],
      ],

      "02Reagents" => [
        [ "Reagent cvterms okay?", false ],
        [ "Reagents submitted to centers?", false ],
        [ "Reagent matches title/filenames", { :controller => :curation, :action => :view_sdrf, :id => @project }, "View SDRF..." ],
        [ "Reagent matches GEO entry?", { :controller => :curation, :action => :geo_sra_ids, :id => @project }, "View GEO and SRA IDs..." ],
      ],

      "03Data Files" => [
        [ "Data files okay?", { :controller => :public, :action => :download, :id => @project }, "View Data Files..." ],
        [ "Peak files for replicates and merged?", false ],
        [ "Raw data files supplied?", { :controller => :public, :action => :download, :id => @project }, "View Data Files..." ],
        [ "If worm, in WS190?", false ],
      ],

      "04Protocols" => [
        [ "Detailed protocol info?", { :controller => :curation, :action => :protocol_pages, :id => @project }, "View Protocol Descriptions..." ],
        [ "Links to software for protocols?", { :controller => :curation, :action => :protocol_pages, :id => @project }, "View Protocol Descriptions..." ],
        [ "Protocol types appropriate?", { :controller => :curation, :action => :protocol_types, :id => @project }, "View Protocol Types..." ],
      ],

      "05Antibodies" => [
        [ "Antibody wiki page complete?", { :controller => :curation, :action => :antibody_pages, :id => @project }, "View Antibody Pages..." ],
        [ "Histone modification wiki page if necessary?", false ],
        [ "No antibody QC problems from validator?", { :controller => :curation, :action => :validator_results, :id => @project }, "View Last Validator Results..." ],
      ],

      "06Seq Experiments" => [
        [ "Total reads and mapped reads provided?", { :controller => :curation, :action => :validator_results, :id => @project }, "View Last Validator Results..." ],
        [ "Sequencing size selection done if indicated?", false ],
        [ "Mapping algorithm in protocol?", { :controller => :curation, :action => :protocol_pages, :id => @project }, "View Protocol Descriptions..." ],
        [ "FASTQ available if appropriate?", { :controller => :public, :action => :download, :id => @project }, "View Data Files..." ],
        [ "Read length captured in protocol?", { :controller => :curation, :action => :view_sdrf, :id => @project }, "View SDRF..." ],
        [ "Sequencing instrument details captured in protocol?", { :controller => :curation, :action => :protocol_pages, :id => @project }, "View Protocol Descriptions..." ],
      ],

      "07Annotations" => [
        [ "Referenced annotation version captured?", false ],
      ],

      "08GBrowse" => [
        [ "Tracks categorized properly?", { :action => :configure_tracks, :id => @project }, "View Configure Tracks..." ],
        [ "Tracks look okay? (Zoomed?)", { :controller => :curation, :action => :browser, :id => @project }, "View Tracks in GBrowse..." ],
        [ "SAM reads aligned properly?", { :controller => :curation, :action => :browser, :id => @project }, "View Tracks in GBrowse..." ],
      ]
    }


    @project_needs_release = Project::Status::ok_next_states(@project).include?(Release::Status::AWAITING_RELEASE)

    @project_replaces_deprecated_project = Project.find_by_deprecated_project_id(@project.id)
    while (@project_replaces_deprecated_project && !(p = Project.find_by_deprecated_project_id(@project_replaces_deprecated_project.id)).nil?)
      @project_replaces_deprecated_project = p
    end
    last_release = @project.commands.all.find_all { |cmd| cmd.is_a?(Release) && cmd.status != Release::Status::RELEASE_REJECTED }.sort { |up1, up2| up1.end_time <=> up2.end_time }.last
    if last_release && !last_release.backdated_by_project.nil? then
      # There was a previous release, and we explicitly chose to
      # use deprecated dates
      @use_deprecated_dates = true
      @project_replaces_deprecated_project = last_release.backdated_by_project
    elsif !last_release.nil? then
      # There was a previous release, and we didn't choose to use
      # deprecated dates
      @use_deprecated_dates = false
    else
      # We don't know any better, so if possible, we'll assume we want to use
      # deprecated dates
      @use_deprecated_dates = true
    end
    @last_release = last_release

    # Handle form click
    if params[:commit] == "Release" then
      is_okay = true
      @checklist_for_data_validation.each { |task| 
        is_okay = false unless task[:done]
      }
      @checklist_for_release_by_pi.values.flatten(1).each { |task| 
        is_okay = false unless params[task[0]]
      }
      if is_okay then
        if @use_deprecated_dates && @project_replaces_deprecated_project then
          do_user_release(@project, :stderr => "Backdated to submission ##{@project_replaces_deprecated_project.id}.")
        else
          do_user_release(@project)
        end
        redirect_to :action => :show, :id => @project
        return
      else
        flash[:error] = "All checkboxes must be checked to release this submission."
      end
    end
    if params[:commit] == "Release as DCC" then
      is_okay = true
      @checklist_for_data_validation.each { |task| 
        is_okay = false unless task[:done]
      }
      @checklist_for_release_by_pi.values.flatten(1).each { |task| 
        is_okay = false unless params[task[0]]
      }
      if is_okay then
        reservations = params[:with_reservations] ? params[:reservations] : nil
        if params[:use_deprecated_release_date] && @project_replaces_deprecated_project then
          do_dcc_release(@project, :stderr => "Backdated to submission ##{@project_replaces_deprecated_project.id}.", :reservations => reservations)
        else
          do_dcc_release(@project, :reservations => reservations)
        end
        redirect_to :action => :show, :id => @project
        return
      else
        flash[:error] = "All checkboxes must be checked to release this submission -- even for you, DCC user."
      end
    end
    if params[:commit] == "Reject as DCC" then
      do_dcc_reject(@project, :reason => params[:reason])
      redirect_to :action => :show, :id => @project
      return
    end
    if params[:commit] then
      redirect_to :action => :release, :id => @project
    end

  end

  def publish
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

    unless current_user.is_a?(Moderator) then
      flash[:error] = "Only moderators can update publication dates."
      redirect_to :action => "list"
      return
    end
    
    @time_format = "%a, %b %d, %Y (%H:%M)"
    @publish_types = {
      "modMine" => { :class => PublishToModMine },
      "GBrowse" => { :class => PublishToGbrowse },
      "GEO"     => { :class => PublishToGEO }
    }
    @publish_types.each { |name, command|
      command[:command] = command[:class].find(:last, :conditions => { :project_id => @project.id })
    }

    if params[:publish_type] && params[:publish_type].length > 0 then
      if params[:publish_type] == "deprecate" || params[:publish_type] == "retract" then
        flash.clear ; flash.discard
        if params[:publish_type] == "retract" || (params[:deprecated_by] && params[:deprecated_by].length > 0 && params[:deprecated_by] != "no new project") then
          begin
            if params[:publish_type] == "retract" then
              @project.deprecated_project_id = 0
            else
              deprecated_by = Project.find(params[:deprecated_by].to_i)
              @project.deprecated_by_project = deprecated_by
            end
            @project.save
          rescue ActiveRecord::RecordNotFound => e
            flash[:error] = "Couldn't find the submission that this submission was deprecated by: #{e.message}"
            return
          end
        else
          @project.deprecated_project_id = 0
          @project.save
          flash[:warning] = "Did not set a submission that this submission was deprecated by. Please fill one in if it exists."
        end
        if params[:deprecate_remove_published] == "true" then
          @publish_types.each do |name, command|
            unless command[:command].nil? then
              command[:command].destroy
            end
          end
        end
        redirect_to :action => :publish
      elsif params[:publish_type] == "supersede" then
        flash.clear ; flash.discard
        if params[:superseded_by] && params[:superseded_by].length > 0 && params[:superseded_by] != "no new project" then
          begin
            superseded_by = Project.find(params[:superseded_by].to_i)
            @project.superseded_by_project = superseded_by
            @project.save
          rescue ActiveRecord::RecordNotFound => e
            flash[:error] = "Couldn't find the submission that this submission was superseded by: #{e.message}"
            return
          end
        else
          @project.superseded_project_id = 0
          @project.save
          flash[:warning] = "Did not set a submission that this submission was superseded by. Please fill one in if it exists."
        end
        if params[:supersede_remove_published] == "true" then
          @publish_types.each do |name, command|
            unless command[:command].nil? then
              command[:command].destroy
            end
          end
        end
        redirect_to :action => :publish
      else
        unpublish = false
        if params[:publish_type] =~ /_unpublish$/ then
          unpublish = true
          params[:publish_type] = params[:publish_type].sub(/_unpublish$/, '')
        end

        publish_class = @publish_types.find { |name, command| command[:class].name.to_s == params[:publish_type] }
        unless publish_class then
          flash[:warning] = "Invalid publish type: #{params[:publish_type]}";
          redirect_to :action => :publish
          return
        end
        
        if unpublish then
          if publish_class[1][:command] then
            publish_class[1][:command].destroy
          else
            flash[:warning] = "Not unpublishing from #{publish_class[0]}; not published to begin with."
          end
          redirect_to :action => :publish
          return
        end


        date_field = publish_class[1][:class].name + "_date"
        new_date = Time.now
        if !params[date_field].empty? && params[date_field] != "never published" then
          # A date was given
          date = params[date_field]
          if (date !~ /\d\d\d\d-\d\d-\d\d \d\d:\d\d/) then
            if Time.parse(date).strftime(@time_format) != date then
              flash[:warning] = "Nonstandard time format. To avoid this message use YYYY-MM-DD HH:MM."
            end
          end
          new_date = Time.parse(date)
        end


        if publish_class[1][:command] then
          # Update date
          pub = publish_class[1][:command]
          pub.start_time = new_date
          pub.end_time = new_date
          pub.user = current_user
          pub.save
        else
          # Make a new one
          pub = publish_class[1][:class].new(:project => @project)
          pub.save
          pub.start_time = new_date
          pub.end_time = new_date
          pub.user = current_user
          pub.save
        end
        redirect_to :action => :publish
      end
    end
  end

  def do_user_release(project, options = {})
    release_controller = nil
    if Release::Status::constants.map { |c| Release::Status::const_get(c) }.include?(project.status) then
      release_controller = UserReleaseController.new(:project => project, :status => project.status, :stderr => options[:stderr])
    else
      release_controller = UserReleaseController.new(:project => project, :stderr => options[:stderr])
    end
    release_controller.run
  end

  def do_dcc_release(project, options = {})
    release_controller = nil
    if Release::Status::constants.map { |c| Release::Status::const_get(c) }.include?(project.status) then
      release_controller = DccReleaseController.new(:project => project, :status => project.status, :stderr => options[:stderr], :reservations => options[:reservations])
    else
      release_controller = DccReleaseController.new(:project => project, :stderr => options[:stderr], :reservations => options[:reservations])
    end
    release_controller.run
  end

  def do_dcc_reject(project, options = {})
    reject_controller = DccRejectController.new(:project => project, :stderr => options[:reason]);
    reject_controller.run
    # Unaccept config(s) for this project if any have been accepted
    TrackStanza.find_all_by_project_id(project.id).each { |ts|
      ts.released = false
      ts.save
    }
  end

  def project=(proj)
    @project = proj
  end

  def do_preview(project, options = {})
    # Get the *Controller class to be used to do track finding
    preview_controller = PreviewBrowserController.new(:project => project, :current_status => project.status)
    options[:user] = current_user
    preview_controller.queue options
  end

  def do_find_tracks(project, options = {})
    # Get the *Controller class to be used to do track finding
    TrackStanza.destroy_all(:user_id => current_user.id, :project_id => project.id)
    find_tracks_controller = FindTracksController.new(:project => project, :user_id => current_user.id)
    options[:user] = current_user
    find_tracks_controller.queue options
  end

  def do_find_tracks_fast(project, options = {})
    # Get the *Controller class to be used to do track finding
    TrackStanza.destroy_all(:user_id => current_user.id, :project_id => project.id)
    find_tracks_controller = FindTracksFastController.new(:project => project, :user_id => current_user.id)
    options[:user] = current_user
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
    options[:user] = current_user
    load_controller.queue options
  end

  def do_report(project, options = {})
    # Get the *Controller class to be used to do reporting
    begin
      report_class = getProjectType(project).reporter_wrapper_class.singularize.camelize.constantize
    rescue
      report_class = Report
    end

    if report_class.ancestors.map { |a| a.name == 'CommandController' }.find { |a| a } then
      report_controller_class = report_class
    else
      # Command.is_a? Command
      if report_class.ancestors.map { |a| a.name == 'Command' }.find { |a| a } then
        begin
          report_controller_class = (report_class.name + "Controller").camelize.constantize
        rescue
          report_controller_class = ReportController
        end
      else
        throw :expecting_subclass_of_command_or_command_controller
      end
    end

    report_controller = report_controller_class.new(:project => project)
    options[:user] = current_user
    report_controller.queue options
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
    options[:user] = current_user
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
    options[:user] = current_user
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


    options[:user] = current_user
    expand_controller.queue options
    cmd_obj = expand_controller.command_object
  end

  def do_upload(upurl, upftp, upfile, uprsync, 
                upcomment, filename)
    # TODO: Make this function private

    # Create a ProjectArchive to handle the upload
    (project_archive = @project.project_archives.new).save 
    # We save it so we get an archive_no
    project_archive.file_name = "#{"%03d" % project_archive.attributes[project_archive.position_column]}_#{filename}"
    project_archive.file_date = Time.now
    project_archive.is_active = false
    project_archive.comment = upcomment
    project_archive.save


    # Build a Command::Upload object to fetch the file
    if !upurl.blank? || upurl == "http://" then
      # Uploading from a remote URL; use open-uri
      # (http://www.ruby-doc.org/stdlib/libdoc/open-uri/rdoc/)
      projectDir = path_to_project_dir(@project)

      upload_controller = UrlUploadController.new(:source => upurl,
        :filename => path_to_file(project_archive.file_name),
        :project => @project)
      upload_controller.timeout = 36000 # 10 hours

      # Queue url upload command
      upload_controller.queue(:user => current_user)
    elsif !upftp.blank?
      # Uploading from the FTP site
      upload_controller = FtpUploadController.new(:source => upftp,
        :filename => path_to_file(project_archive.file_name),
        :project => @project)
      upload_controller.timeout = 36000 # 10 hours

      # Queue ftp upload command
      upload_controller.queue(:user => current_user)
    elsif !uprsync.blank? || uprsync == "rsync://"
      # Uploading via rsync - similar to URL
      upload_controller = RsyncUploadController.new(:source => uprsync, 
        :filename => path_to_file(project_archive.file_name),
        :project => @project)
     upload_controller.timeout = 36000 # 10 hours
     # Queue rsync upload command
     upload_controller.queue( :user => current_user )  
    else
      # Uploading from the browser
      if !upfile.local_path
        File.open(path_to_file(project_archive.file_name), "wb") { |f| f.write(upfile.read) }
        upload_controller = FileUploadController.new(:source => path_to_file(project_archive.file_name), :filename => path_to_file(project_archive.file_name), :project => @project)
        upload_controller.timeout = 20 # 20 seconds
      else
        upload_controller = FileUploadController.new(:source => upfile.local_path, :filename => path_to_file(project_archive.file_name), :project => @project)
        upload_controller.timeout = 600 # 10 minutes
      end

      # Immediately run upload command
      # (Since this was uploaded from a browser, need to copy the file before the tmp file dissapears)
      upload_controller.command_object.user = current_user
      upload_controller.command_object.save
      upload_controller.run

      # Rexpand all active archives for this project
      queue_reexpand_project(@project)
      CommandController.do_queued_commands
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
    unless project.user_id == current_user.id || project.same_pi?(current_user.lab) || current_user.is_a?(Administrator) || current_user.is_a?(Moderator)
      flash[:error] = "This project does not belong to you." unless options[:skip_redirect] == true 
      redirect_to :action => 'show', :id => project unless options[:skip_redirect] == true 
      return false
    end
    if project.user_id != current_user.id then
      flash.discard(:warning)
      flash[:warning] = "Note: This project (#{project.name}) does not belong to you, but you are allowed to make changes." unless options[:skip_redirect] == true 
    end
    if project.status == Project::Status::RELEASED then
      flash[:notice] = flash[:notice].to_s + "This project has been released and cannot be modified."
      return false
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
    unless project.user_id == current_user.id || project.same_pi?(current_user.lab) || current_user.is_a?(Administrator) || current_user.is_a?(Moderator) || current_user.is_a?(Reviewer)
      flash[:error] = "That project does not belong to you." unless options[:skip_redirect] == true 
      redirect_to :action => "list" unless options[:skip_redirect] == true 
      return false
    end
    return true
  end

  # --- file upload routines ---
  def self.sanitize_filename(file_name)
    # get only the filename, not the whole path (from IE)
    just_filename = File.basename(file_name) 
    # replace all non-alphanumeric, underscore or periods with underscore
    just_filename.gsub(/[^\w\.\_]/,'_') 
  end
  def sanitize_filename(file_name)
    PipelineController::sanitize_filename(file_name)
  end

  def path_to_project_dir(project = nil)
    project = @project if project.nil?
    # the expand_path method resolves this relative path to full absolute path
    File.expand_path("#{ActiveRecord::Base.configurations[RAILS_ENV]['upload']}/#{project.id}")
  end

  def path_to_file(filename)
    # the expand_path method resolves this relative path to full absolute path
    File.join(path_to_project_dir, filename)
  end
  
  # Takes : full path to file
  # Returns : md5 checksum of the first 50,000,000 bytes of the file
  def generate_file_signature(filepath)
    bytes_to_md5 = 50000000
    return nil unless File.size? filepath
    return Digest::MD5.hexdigest(File.read(filepath, bytes_to_md5))
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

  def queue_reexpand_project(project, after_command = nil)
    # Delete everything in the extracted dir since it's no longer up-to-date
    unless project.project_archives.first.nil? then
      ExpandController.remove_extracted_folder(project.project_archives.first)
    end

    # Rexpand any active archives from oldest to newest
    current_project_archive = project.project_archives.first
    cmds = Array.new
    while (current_project_archive)
      cmds.push do_expand(current_project_archive, :defer => true) if current_project_archive.is_active
      current_project_archive = current_project_archive.lower_item
    end
    if after_command then
      # Move just queued commands in front of the first queued command
      cmds.reverse.each { |cmd|
        cmd.queue_insert_at(after_command.queue_position+1)
        cmd.insert_at(after_command.position+1)
      }
    end
  end
  def cancel_upload
    unless current_user && (current_user.is_a?(Administrator) || current_user.login == "nbild") then
      redirect_to :action => :list
      return
    end
    begin
      @project = Project.find(params[:id])
      return false unless check_user_can_write @project
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end

    @project.commands.find_all_by_status(Upload::Status::UPLOADING).each { |cmd|
      cmd.status = Upload::Status::UPLOAD_FAILED
      cmd.save
    }
    redirect_to :action => :show, :id => @project
  end
  def ftp_selector
    @ftpMount = File.expand_path(ActiveRecord::Base.configurations[RAILS_ENV]['ftpMount'])
    @selected_dir = params[:dir] || "."
    @selected_dir = File.expand_path(File.join(@ftpMount, @selected_dir))
    unless @selected_dir.start_with?(@ftpMount) then
      @selected_dir = @ftpMount
    end
    @selected_dir = @ftpMount unless File.directory?(@selected_dir)
    mount = Dir.new(@selected_dir)

    @files = Array.new
    @dirs = Array.new
    mount.each { |file|
      next if file == "."
      @files.push file
    }

    @selected_dir = @selected_dir[(@ftpMount.length)..-1]
    render :layout => false
  end
private

  def copy_stanza(user_id, old_project_id, new_project_id)
    oldts = TrackStanza.find_by_project_id_and_released(old_project_id, true)
    oldts = TrackStanza.find_by_project_id_and_user_id(old_project_id, user_id) unless oldts
    newts = TrackStanza.find_by_project_id_and_user_id(new_project_id, user_id)

    return "Cannot find both old and new track stanzas" unless oldts && newts

    newstanza = Hash.new

    old_tracks = oldts.stanza.sort { |t1, t2| t1[0].match(/_(\d+)_\d+$/)[1] <=> t2[0].match(/_(\d+)_\d+$/)[1] }
    new_tracks = newts.stanza.sort { |t1, t2| t1[0].match(/_(\d+)_\d+$/)[1] <=> t2[0].match(/_(\d+)_\d+$/)[1] }

    diff = new_tracks[0][0].match(/_(\d+)_\d+$/)[1].to_i - old_tracks[0][0].match(/_(\d+)_\d+$/)[1].to_i

    old_tracks.each_index { |old_index|
      (track_name, values) = old_tracks[old_index]
      (tracktype, details) = values["feature"].match(/^(.*):\d+(_details)?$/)[1..2]
      (tracknum, projnum) = track_name.match(/_(\d+)_(\d+)$/)[1].to_i

      (tn, vs) = new_tracks[old_index]
      $stderr.puts "Tracktype: #{tracktype}, Details: #{details}"
      (tracktp, deets) = vs["feature"].match(/^(.*):\d+(_details)?$/)[1..2]

      if !(tracktype == tracktp && details == deets) then
        return "Cannot deal with mismatched types #{tracktype}#{details} != #{tracktp}#{deets}"
      end


      copy_of_old = Marshal.restore(Marshal.dump(values))
      copy_of_old["feature"] = vs["feature"] # Keep new feature type and num
      copy_of_old["key"] = vs["key"] # Keep new key name
      copy_of_old["database"] = vs["database"] # Keep new database schema name
      copy_of_old["citation"] = vs["citation"] # Keep new citation schema name

      old_zoom_level = copy_of_old[:semantic_zoom]

      copy_of_old[:semantic_zoom] = Hash.new if !vs[:semantic_zoom].values.first

      if copy_of_old[:semantic_zoom].values.first then
        copy_of_old[:semantic_zoom].values.first["feature"] = vs[:semantic_zoom].values.first["feature"] # Keep new feature type and num
        copy_of_old[:semantic_zoom].values.first["key"] = vs[:semantic_zoom].values.first["key"] # Keep new key name
        copy_of_old[:semantic_zoom].values.first["database"] = vs[:semantic_zoom].values.first["database"] # Keep new database schema name
        copy_of_old[:semantic_zoom].values.first["citation"] = vs[:semantic_zoom].values.first["citation"] # Keep new citation schema name
        copy_of_old[:semantic_zoom].values.first.reject! { |k, v| v == nil }
      end

      newstanza[tn] = copy_of_old
    }

    newts.stanza = newstanza
    return newts.save
  end
  def status
    user_to_view = session[:show_filter_user].nil? ? current_user : User.find(session[:show_filter_user])
    @current_pis = current_user.nil? ? [] : current_user.pis
    pis_to_view = (session[:show_filter_pis].nil? || session[:show_filter_pis] == "") ? @current_pis : session[:show_filter_pis]

    @viewing_user = user_to_view if user_to_view != current_user
    @viewing_pis = pis_to_view if pis_to_view != @current_pis

    @show_filter_pis = Array.new
    same_group_users = User.all.find_all { |u| (u.pis & user_to_view.pis).size > 0 }
    if session[:show_filter] == :user then
      @projects = user_to_view.projects
      @show_my_queue = user_to_view
    elsif session[:show_filter] == :group then
      @projects = pis_to_view.size > 0 ? Project.find_all_by_pi(pis_to_view) : Project.all
      @show_filter_pis = pis_to_view
    else  
      @projects = Project.all
    end
    @projects.delete_if { |p| p.deprecated? }

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
        p1_attrs = sorts.map { |col| 
          sort_attr = (session[:sort_list][col][0] == 'backward') ?  p2.send(col) : p1.send(col)
          sort_attr = Project::Status::state_position(sort_attr) if col == "status"
          sort_attr = sort_attr.nil? ? -999 : sort_attr
        } << p1.id
        p2_attrs = sorts.map { |col| 
          sort_attr = (session[:sort_list][col][0] == 'backward') ?  p1.send(col) : p2.send(col) 
          sort_attr = Project::Status::state_position(sort_attr) if col == "status"
          sort_attr = sort_attr.nil? ? -999 : sort_attr
        } << p2.id
        p1_attrs.nil_flatten_compare p2_attrs
      }
      session[:sort_list].each_pair { |col, srtby| @new_sort_direction[col] = 'backward' if srtby[0] == 'forward' && sorts[0] == col }
    else
      @projects = @projects.sort { |p1, p2| p1.name <=> p2.name }
    end

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
    @num_pages = @projects.size / page_size
    @num_pages += 1 if @projects.size % page_size != 0
    @has_next_page = @cur_page != @num_pages
    @has_prev_page = @cur_page != 1
    @projects = @projects[page_offset...page_end]



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

    @status_names = {
      Project::Status::NEW => "New",
      Project::Status::UPLOADED => "Uploaded",
      Project::Status::VALIDATED => "Validated",
      Project::Status::LOADED => "DBLoad",
      Project::Status::FOUND => "Trk found",
      Project::Status::CONFIGURED => "Configured",
      Project::Status::AWAITING_RELEASE => "Needs attn",
      Project::Status::USER_RELEASED => "Aprvl-PI",
      Project::Status::DCC_RELEASED => "Aprvl-DCC",
      Project::Status::RELEASED => "Aprvl-BOTH",
    }
    @status = [
      "New", "Uploaded", "Validated", "DBLoad", "Trk found", "Configured", "Needs attn", "Aprvl-PI", "Aprvl-DCC", "Aprvl-BOTH",
    ]

    @pis = Project.all.map { |p| p.pi }.uniq

    @active_status = @status[0..6]

    @all_projects_by_status = Hash.new {|hash,status| hash[status] = 0 }
    @my_projects_by_status = Hash.new {|hash,status| hash[status] = 0 }
    @my_groups_projects_by_status = Hash.new {|hash,status| hash[status] = 0 }
    @my_active_projects_by_status = Hash.new {|hash,status| hash[status] = 0 }
    @projects.each { |p|
      @all_projects_by_status[@status_names[p.status]] += 1 unless @pis.index(p.pi.split(",")[0]).nil?
      @my_projects_by_status[@status_names[p.status]] += 1 if p.user_id == user_to_view.id
      @my_groups_projects_by_status[@status_names[p.status]] += 1 if same_group_users.index(p.user_id).nil?
      @my_active_projects_by_status[@status_names[p.status]] += 1 if p.user_id == user_to_view.id && @status_names.keys[0..6].include?(p.status)
    }

    @all_my_new_projects_per_quarter = Hash.new {|hash,quarter| hash[quarter] = 0 }
    # initialize to make sure all PIs are included; require each status to be represented
    @quarters.each{|k,v| @all_my_new_projects_per_quarter[k] = 0 unless v["start"] > Time.now.to_date}

    @projects.map{|p| @all_my_new_projects_per_quarter[@quarters.find{|k,v| p.created_at.to_date <= v["end"] && p.created_at.to_date >= v["start"]}[0]] += 1 }


    @all_my_released_projects_per_quarter = Hash.new {|hash,quarter| hash[quarter] = 0 }
    # initialize to make sure all PIs are included; require each status to be represented
    @quarters.each{|k,v| @all_my_released_projects_per_quarter[k] = 0 unless v["start"] > Time.now.to_date}

    @released_projects = @projects.find_all{|p| p.status=="released"}
    #for now, will use the last updated date, but should probably find the release command, and use that
    @released_projects.map{|p| @all_my_released_projects_per_quarter[@quarters.find{|k,v| p.updated_at.to_date <= v["end"] && p.updated_at.to_date >= v["start"]}[0]] += 1 }
  end

end
