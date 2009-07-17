#!/usr/bin/ruby

require 'cgi'
require 'socket'
require 'rubygems'
require '../../submit/config/environment'

path_prefix = "/srv/www/data/pipeline_public"
if Socket.gethostname == "smaug" then
  path_prefix = "/var/www/data/pipeline"
end


if ARGV[0] && ARGV[0] !~ /worm|fly/ then
  preview_conf = File.join(path_prefix, ARGV[0], "/browser/", "#{ARGV[0]}.conf");
  if File.exist?(preview_conf) then
    File.open(preview_conf) { |f|
      conf_text = f.read
      organism = (conf_text =~ /##species worm/) ? "worm" : "fly"
      File.open("../conf/modencode_#{organism}.conf") { |f2|
        puts f2.read
      }
      puts conf_text
    }
  end
else
  # Show all previews
  organism = ARGV[0]
  organism = "fly" unless organism

  File.open("../conf/modencode_#{organism}.conf") { |f|
    puts f.read
  }

  conf_name = "../conf/tmp_conf/modencode_preview_#{organism}.conf"
  if File.exist?(conf_name) && (Time.now - File.mtime(conf_name)) < 600 then
    File.open(conf_name) { |f|
      puts f.read
    }
  else
    File.open(conf_name, "w") { |conf_file|
      Project.all.find_all { |p| p.has_preview? }.each { |p|
        preview_conf = File.join(path_prefix, p.id.to_s, "/browser/", "#{p.id}.conf");
        if File.exist?(preview_conf) then
          File.open(preview_conf) { |f|
            text = f.read
            if (text =~ /##species #{organism}/) then
              puts text
              conf_file.puts text
            end
          }
        end
      }
    }
  end
end
