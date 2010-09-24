class CurationController < ApplicationController
  before_filter :login_required, :except => :tickle_me_here
  def geo_sra_ids
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :controller => "pipeline", :action => "release", :id => params[:id]
      return
    end
    @sra_ids = TrackTag.find_all_by_project_id_and_cvterm(@project.id, "ShortReadArchive_project_ID (SRA)").map { |tt| tt.value }
    @geo_ids = TrackTag.find_all_by_project_id_and_cvterm(@project.id, "GEO_record").map { |tt| tt.value }
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
    @antibodies = TrackTag.find_all_by_project_id_and_cvterm(@project.id, 'antibody').map { |ab|
      { "name" => ab["value"].sub(/\&oldid.*/, ''), "url" => ab["value"] }
    }.uniq
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
