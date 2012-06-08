class CurationController < ApplicationController
  include GeoidHelper
  before_filter :login_required, :except => :tickle_me_here
  before_filter :moderator_required, :only => [:attach_geoids, :attach_geoids_db] 
  layout "pipeline", :only => [:attach_geoids, :attach_geoids_db]

  def moderator_required
    access_denied unless current_user.is_a? Moderator 
  end

  def geo_sra_ids
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :controller => "pipeline", :action => "release", :id => params[:id]
      return
    end
    @sra_ids = TrackTag.find_all_by_project_id_and_cvterm(@project.id, "ShortReadArchive_project_ID (SRA)").map { |tt| tt.value }
    @sra_ids += TrackTag.find_all_by_project_id_and_cvterm(@project.id, "data_url").find_all { |tt| tt.name =~ /^SRA|^SRR/ }.map { |tt| tt.name }
    @geo_ids = TrackTag.find_all_by_project_id_and_cvterm(@project.id, "GEO_record").map { |tt| tt.value }
    @geo_ids += TrackTag.find_all_by_project_id_and_cvterm(@project.id, "data_url").find_all { |tt| tt.name =~ /^GSE|^GSM/ }.map { |tt| tt.name }
    @sra_ids.compact!
    @sra_ids.delete_if { |t| t == "" }
    @sra_ids.uniq!
    @geo_ids.compact!
    @geo_ids.delete_if { |t| t == "" }
    @geo_ids.uniq!
  end
  def experiment_description
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :controller => "pipeline", :action => "release", :id => params[:id]
      return
    end
    dbinfo = CurationController.database
    dbh = DBI.connect(dbinfo[:dsn], dbinfo[:user], dbinfo[:password])
    require 'pg_database_patch'
    dbh.execute("SET search_path = modencode_experiment_#{@project.id}_data")
    sth = dbh.prepare("SELECT ep.value, dbx.accession FROM dbxref dbx INNER JOIN experiment_prop ep ON dbx.dbxref_id = ep.dbxref_id WHERE ep.name = 'Experiment Description'")
    sth.execute
    res = sth.fetch_hash
    sth.finish
    @experiment_description_url = res["accession"];
    @experiment_description = res["value"];
  end
  def browser
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :controller => "pipeline", :action => "release", :id => params[:id]
      return
    end
    organism = @project.released_organism
    unless organism then
      tt = TrackTag.find_by_project_id_and_cvterm(@project.id, "species")
      organism = tt.value unless tt.nil?
    end
    organism ||= organisms_by_pi[@project.pi]
    browser = organism.downcase.sub(/^(.)\W*(\w\w\w).*/, '\1\2')
    browser = "flybase" if browser == "dmel"
    browser = "wormbase" if browser == "cele"
    url = "/gbrowse/cgi-bin/gbrowse/modencode_#{browser}_quick_#{@project.id}/"
    redirect_to url
  end
  def view_sdrf
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :controller => "pipeline", :action => "release", :id => params[:id]
      return
    end
    look_in = File.join(PipelineController.new.path_to_project_dir(@project), "extracted", "**")
    sdrfs = Dir.glob(File.join(look_in, "*SDRF*")) + Dir.glob(File.join(look_in, "*sdrf*"))
    # Ignore any sdrf with unattached GeoIDs
    sdrfs.reject!{|f| f.include? AttachGeoidsController::NEW_SDRF_SUFFIX}
    if sdrfs.size > 0 && File.exists?(sdrfs.first) then
      @sdrf = File.read(sdrfs.first)
    end
  end
  def protocol_pages
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :controller => "pipeline", :action => "release", :id => params[:id]
      return
    end
    dbinfo = CurationController.database
    dbh = DBI.connect(dbinfo[:dsn], dbinfo[:user], dbinfo[:password])
    require 'pg_database_patch'
    dbh.execute("SET search_path = modencode_experiment_#{@project.id}_data")
    sth = dbh.prepare("SELECT p.name, dbx.accession AS url FROM dbxref dbx INNER JOIN protocol p ON dbx.dbxref_id = p.dbxref_id")
    sth.execute
    @protocols = Array.new
    sth.fetch_hash { |row|
      @protocols.push row
    }
    sth.finish
  end
  def protocol_types
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :controller => "pipeline", :action => "release", :id => params[:id]
      return
    end
    dbinfo = CurationController.database
    dbh = DBI.connect(dbinfo[:dsn], dbinfo[:user], dbinfo[:password])
    require 'pg_database_patch'
    dbh.execute("SET search_path = modencode_experiment_#{@project.id}_data")
    sth = dbh.prepare("SELECT p.name, dbx.accession AS url, a.value AS type FROM protocol p INNER JOIN dbxref dbx ON dbx.dbxref_id = p.dbxref_id INNER JOIN protocol_attribute pa ON p.protocol_id = pa.protocol_id INNER JOIN attribute a ON pa.attribute_id = a.attribute_id WHERE a.heading = 'Protocol Type'")
    sth.execute
    @protocols = Array.new
    sth.fetch_hash { |row|
      @protocols.push row
    }
    sth.finish
  end
  def antibody_pages
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :controller => "pipeline", :action => "release", :id => params[:id]
      return
    end
    @antibodies = TrackTag.find_all_by_project_id_and_cvterm(@project.id, 'antibody').reject { |ab| ab.value.nil? }.map { |ab|
      { "name" => ab["value"].sub(/\&oldid.*/, ''), "url" => ab["value"] }
    }.uniq
    if (@antibodies.size == 0) then
      @antibodies = TrackTag.find_all_by_project_id_and_cvterm(@project.id, 'target name').reject { |ab| ab.value.nil? }.map { |ab|
        { "name" => ab["name"].sub(/\&oldid.*/, ''), "url" => ab["name"] }
      }.uniq
    end

  end
  def validator_results
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :controller => "pipeline", :action => "release", :id => params[:id]
      return
    end
    last_validate = @project.commands.find_all { |cmd| cmd.is_a?(ValidateIdf2chadoxml) }.last
    if last_validate
      redirect_to :controller => :pipeline, :action => :command_status, :id => last_validate.id
    else 
      render :text => "No validation command found to confirm!"
    end
  end
  def attach_geoids
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :controller => "pipeline", :action => "release", :id => params[:id]
      return
    end
    # First, ensure the project is in an appropriate state
    unless (Project::Status::ok_next_states(@project).include? Project::Status::AWAITING_RELEASE) || 
           (@project.released?) then
      flash[:error] = "Can't attach Geo IDs to this project until tracks have been configured!"
      redirect_to :controller => "pipeline", :action => "show", :id => params[:id]
    end

    # Submitting the form
    if params[:commit] == "Attach GEOids" then
      gse = params[:gse].upcase
      # GSMS are separated by commas and/or spaces
      gsms = params[:gsms].upcase.gsub(",", " ").split(/\s+/)
      # Check GSE and GSMS for reasonableness
      unless (gse =~ /^GSE\d+$/) && (gsms.reject{|g| g =~ /^GSM\d+$/}.empty? ) then
        flash[:error] =  "Error: A GSE or GSM was invalid.<br/><br/>Input GSE:<br/>#{gse}<br/><br/>Input GSMs:<br/>#{gsms.join("<br/>")}"
        redirect_to :controller => "curation", :action => "attach_geoids", :id => params[:id]
        return
      end
      # Also check for uniqueness of GSMs
      unless gsms.uniq == gsms then
        flash[:error] = "Error: Duplicate GMSs found&mdash;GSMs must be unique.<br/><br/>Input GSE:<br/>#{gse}<br/><br/>Input GSMs:<br/>#{gsms.join("<br/>")}"
        redirect_to :controller => "curation", :action => "attach_geoids", :id => params[:id]
        return
      end

      # Make controller, creating the geoids marshal object but not attaching it to DB
      attach_geoids = AttachGeoidsController.new(
                                                 :gse => gse, 
                                                 :gsms => gsms.join(","), 
                                                 :project_id => @project.id,
                                                 :creating => true,
                                                 :attaching => false
                                                )
      # If it failed to initalize, complain; otherwise, go ahead and queue
      if attach_geoids.command_object.nil? then
        flash[:error] = "Couldn't make AttachGeoids controller! <br> Perhaps there are zero or multiple sdrf files extracted for project #{params[:id]}."
        redirect_to :controller => "curation", :action => "attach_geoids", :id => params[:id]
      else
        attach_geoids.run
        # Check for completion
        if attach_geoids.status == AttachGeoids::Status::CREATED then
          flash[:notice] = "Created GEOids! Please confirm to attach them to the database."
          redirect_to :controller => "curation", :action => "attach_geoids_db", :id => params[:id]
          return
        else
          # Failed to create geoids! whoops! Display error log
          flash[:error] = attach_geoids.command_object.stderr
          redirect_to :controller => "curation", :action => "attach_geoids", :id => params[:id]
          return
        end
      end
    else
      # Just displaying page - Get the sdrf data and existing geoids
      view_sdrf()
      geo_sra_ids()
    end
  end

  def attach_geoids_db
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :controller => "pipeline", :action => "release", :id => params[:id]
      return
    end
 
    # Find the directory for sdrf and marshal files
    lookup_dir = File.join(ExpandController.path_to_project_dir(@project), "extracted")
    # If there's nothing there but a subfolder, assume everything is in there; otherwise, stick with the extracted dir
    entries = Dir.glob(File.join(lookup_dir, "*")).reject{|f| f =~ /\.chadoxml$|\/ws\d+$/ }
    lookup_dir = entries.first if ( (entries.size == 1) && File.directory?(entries.first) )


    # TODO, find marshal file maybe in subdir
    geoid_marshal = File.join(lookup_dir, GEOID_MARSHAL) 
    
    # Form submission
    if params[:commit] == "Attach GEOids" then
      last_created = AttachGeoids.find_all_by_project_id(@project.id).sort{|a, b| a.id <=> b.id}.last
      last_created.creating = false
      last_created.attaching = true
      last_created.save
      last_created.controller.run
      # Check for completion
      if last_created.status == AttachGeoids::Status::ATTACHED then
        redirect_to :controller => "curation", :action => "attach_geoids", :id => params[:id]
      else
        # Failed to attach!
        flash[:error] = last_created.stderr
        redirect_to :controller => "curation", :action => "attach_geoids_db", :id => params[:id]
      end
    elsif params[:commit] == "Cancel" then
      # Remove any temporary sdrf
      last_created = AttachGeoids.find_all_by_project_id(@project.id).sort{|a, b| a.id <=> b.id}.last
      last_created.controller.delete_temp_sdrf
      # Also remove a marshal file
      if File.exist? geoid_marshal then
        begin
          File.delete geoid_marshal
        rescue Exception => e
          logger.error "Failed to delete #{geoid_marshal}: #{e}"
        end
      end
      redirect_to :controller => "curation", :action => "attach_geoids", :id => params[:id]
    else
      # Just displaying page
      # Get geoids from marshal file. 
      if File.exist? geoid_marshal then
        @info = Marshal.restore(File.open(geoid_marshal))
        else
         @info = {}
      end
      # Check if there is a temp sdrf file already
      temp_sdrf = Dir.glob(File.join(lookup_dir, "*" + AttachGeoidsController::NEW_SDRF_SUFFIX)) 
      @temp_sdrf = ! temp_sdrf.empty? 

      # Get existing TrackTags with GeoIDS so we can warn if overwriting
      geo_sra_ids()
    end
  end

  private
  def self.database
    if File.exists? "#{RAILS_ROOT}/config/idf2chadoxml_database.yml" then
      db_definition = open("#{RAILS_ROOT}/config/idf2chadoxml_database.yml") { |f| YAML.load(f.read) }
      dbinfo = Hash.new
      dbinfo[:dsn] = db_definition['ruby_dsn']
      dbinfo[:user] = db_definition['user']
      dbinfo[:password] = db_definition['password']
      return dbinfo
    else
      raise Exception.new("You need an idf2chadoxml_database.yml file in your config/ directory with at least a Ruby DBI dsn.")
    end
  end
  def self.organisms_by_pi
    if File.exists? "#{RAILS_ROOT}/config/pi_organisms.yml" then
      open("#{RAILS_ROOT}/config/pi_organisms.yml") { |f| YAML.load(f.read) }
    else
      {}
    end
  end
end
