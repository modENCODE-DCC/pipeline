#!/usr/bin/ruby

require 'cgi'
require 'openssl'
require 'cgi/session'
require 'rubygems'
#require 'action_controller/session/cookie_store'
#require 'action_controller/cookies'
#require 'action_controller/flash'
#require 'active_support'
require '../../../submit/config/environment'

class String
  def blank?
    return true if self.nil?
    return true if self.size <= 0
  end
end

class CGI
  class Session
    def cgi
      @request
    end
    def cgi=(ncgi)
      @request = ncgi
    end
  end
end

class CGI
  def env_table
    # Don't try to parse POST request, the submitted header has already been read off by GBrowse
    envdup = ENV.clone
    envdup['REQUEST_METHOD'] = "GET" if envdup['REQUEST_METHOD'] == "POST"
    envdup
  end
end

user_id = nil

organism = ARGV[0]

unless ARGV[1].nil? then
  user_id = ARGV[1]
else
  cgi = CGI.new
  session = CGI::Session.new(cgi, 
  'database_manager' => CGI::Session::ActiveRecordStore,
  'session_key' => '_pipeline_dev_session_id',
  'secret' => "ModENCODE secret session key for tracking FastCGI sessions between users"
  )
  session.cgi = cgi
  user_id = session[:user]
end


released_projects = Project.find_all_by_status(Project::Status::RELEASED)
all_track_defs = TrackStanza.find_all_by_project_id(released_projects)
unless user_id.nil? then
  all_pi_users_projects = Project.find_all_by_pi(User.find(user_id).pis)
  all_track_defs += TrackStanza.find_all_by_project_id(all_pi_users_projects)
  # Any pages that this user has configured (mostly useful for moderators)
  all_track_defs += TrackStanza.find_all_by_user_id(user_id)
  if User.find(user_id).is_a?(Moderator) then
    # Released stanzas for all projects
    all_track_defs += TrackStanza.find_all_by_released(true)
  end
else
  # Just get all accepted configurations
  all_track_defs += TrackStanza.find_all_by_released(true)
end
released_project_ids = released_projects.map { |p| p.id }
all_track_defs.each { |ts|
  if !released_project_ids.include?(ts.project_id) then
    s = ts.stanza
    if s then
      s.values.each { |stanza|
        stanza["category"] = "Unreleased: #{stanza["category"]}"
      }
      ts.stanza = s
    else
      ts.stanza = Hash.new
    end
  elsif (ts.project.deprecated?) then
    s = ts.stanza
    s.values.each { |stanza|
      stanza["category"] = "Unreleased: Deprecated: #{stanza["category"]}"
    }
    ts.stanza = s
  end
}


unique_project_ids = all_track_defs.map { |td| td.project_id }.uniq
unique_project_ids.each { |project_id|
  project_tds = all_track_defs.find_all { |td| td.project_id == project_id }
  use_this = project_tds.find { |td| td.released == true } # Released stanza
  use_this = project_tds.find { |td| td.user_id == user_id } unless use_this # This user's stanza
  use_this = project_tds.first unless use_this # A stanza from this user's group

  all_track_defs.delete_if { |td| td.project_id == project_id && td.id != use_this.id }
}

all_track_defs.delete_if { |td| !(Project::Status::ok_next_states(td.project).include?(Project::Status::CONFIGURING) || td.project.status == Project::Status::RELEASED)  }

track_defs = Hash.new
all_track_defs.each { |td| track_defs.merge! td.stanza }

track_defs.reject! { |track, config| 
  stanza_organism = (config[:organism] == "Caenorhabditis elegans") ? "worm" : "fly"
  stanza_organism != organism
}


config_text = `pwd`
File.open("../../conf/modencode_#{organism}.conf") { |file|
  config_text = file.read
}
config_text << "\n\n################AUTOGENERATED PREVIEW TRACKS################\n"

# Databases
if track_defs.nil? then
  puts config_text
  exit
end

seen_dbs = Array.new
track_defs.each do |stanzaname, definition| 
  database = definition['database'] 
  next if database.nil?
  next if seen_dbs.include?(database)
  if database =~ /^modencode_bam_/ then
    project_id = definition["data_source_id"].split(" ").first
    bam_file_path = File.join(ExpandController.path_to_project_id_dir(project_id), "tracks", definition[:bam_file])
    config_text << "[#{database}:database]\n"
    config_text << "db_adaptor    = Bio::DB::Sam\n"
    config_text << "db_args       = -fasta ../../bam_support_fasta/#{organism}.fa\n"
    config_text << "                -bam #{bam_file_path}\n"
    config_text << "                -split_splices 1\n"
    config_text << "\n"
  else
    num = database.gsub(/^modencode_preview_/, '')
    config_text << "[#{database}:database]\n"
    config_text << "db_adaptor    = Bio::DB::SeqFeature::Store\n"
    config_text << "db_args       = -adaptor DBI::Pg\n"
    config_text << "                -dsn     dbname=modencode_gffdb;host=localhost\n"
    config_text << "                -user    'db_public'\n"
    config_text << "                -pass    'ir84#4nm'\n"
    config_text << "                -schema  modencode_experiment_#{num}_data\n"
    config_text << "\n"
  end
end

config_text << "\n"
track_defs.each do |stanzaname, definition|
  next if definition['key'].nil?
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

puts config_text



