#!/usr/bin/ruby

Dir.chdir(File.dirname($0))

require 'cgi'
require 'openssl'
require 'cgi/session'
require 'rubygems'
require 'config/environment'

CommandNotifier.logger.level = Logger::INFO
CommandNotifier.send_batched_notifications
wranglers =
  [
    User.find_by_login("yostinso"),
    User.find_by_login("pruzanov"),
    User.find_by_login("MPerry"),
    User.find_by_login("ellen"),
    User.find_by_login("paul")
  ]

zheng = User.find_by_login("zhengzha")
CommandNotifier.process_geo_notifications(zheng, wranglers, "submit.modencode.org")
