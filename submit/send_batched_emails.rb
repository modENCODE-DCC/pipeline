#!/usr/bin/ruby

Dir.chdir(File.dirname($0))

require 'cgi'
require 'openssl'
require 'cgi/session'
require 'rubygems'
require 'config/environment'

CommandNotifier.logger.level = Logger::INFO
CommandNotifier.send_batched_notifications
