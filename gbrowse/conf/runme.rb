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

all_track_defs = nil

organism = ARGV[0]

unless ARGV[1].nil? then
  all_track_defs = TrackStanza.find_all_by_user_id(ARGV[1])
else
  cgi = CGI.new
  session = CGI::Session.new(cgi, 
  'database_manager' => CGI::Session::CookieStore,
  'session_key' => '_pipeline_dev_session_id',
  'secret' => "ModENCODE secret session key for tracking FastCGI sessions between users"
  )
  session.cgi = cgi

  all_track_defs = TrackStanza.find_all_by_user_id(session[:user])
end

# Use released configs if they exist
released_configs = Array.new
all_track_defs.each { |td|
  released_config = TrackStanza.find_by_project_id_and_released(td.project_id, true)
  released_configs.push released_config if released_config
}
released_configs.each { |td|
  all_track_defs.delete_if { |atd| atd.project_id == td.project_id }
  all_track_defs.push td
}

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

track_defs.map { |stanzaname, definition| definition['database'] }.uniq.each do |database|
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

config_text << "\n"
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

puts config_text



