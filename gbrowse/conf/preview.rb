#!/usr/bin/ruby

require 'cgi'

File.open("../../conf/modencode_fly.conf") { |f|
  puts f.read
}


if ARGV[0] then
  preview_conf = File.join("/var/www/data/pipeline/", ARGV[0], "/browser/", "#{ARGV[0]}.conf");
  if File.exist?(preview_conf) then
    File.open(preview_conf) { |f|
      puts f.read
    }
  end
end
