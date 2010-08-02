#!/usr/bin/ruby
require '/var/www/pipeline/submit/config/environment' # FIXME FOR HEARTBROKEN
require 'find'
require 'fileutils'
# You should run this with sudo -u www-data

puts "Checking the size of files to be lifted over"

# Copied from public_controller because the original is private.
def organisms_by_pi
  if File.exists? "#{RAILS_ROOT}/config/pi_organisms.yml" then
    open("#{RAILS_ROOT}/config/pi_organisms.yml") { |f| YAML.load(f.read) }
  else
    {}
  end
end

def convert_size(content_length)
# converts from bytes to whatever
  if content_length.to_i < 4096 then # 4K
  human_content_length = "#{content_length} bytes"
  elsif content_length.to_i < 4194304 # 4MB
  human_content_length = "#{content_length.to_f/1024.to_f} KB"
  elsif content_length.to_i < 1073741824 # 1 GB
  human_content_length = "#{content_length.to_f/1048576.to_f} MB"
  else
  human_content_length = "#{(content_length.to_f/1073741824.to_f)} GB"
  end

human_content_length
end


# Is this a worm project?
# we'll just check for some variant of elegans
def is_worm(proj)
  organism = proj.released_organism
  organism = organisms_by_pi[proj.pi] if organism.nil?
#  puts "project #{proj.id}-#{proj.pi} has organism #{organism}"
  
  organism =~ /elegans/i
end

data_dir = ActiveRecord::Base.configurations[RAILS_ENV]['upload']
total_size = 0
Dir.foreach(data_dir){|subdir|
  # Ensure that there's a (worm) project & extracted files associated
  begin
    foundproj = Project.find(subdir)
  rescue ActiveRecord::RecordNotFound => whoops
    next
  end
  next unless is_worm(foundproj)
  extracted = File.join(data_dir, subdir, "extracted")
  next unless File.directory? extracted
 
  
  # Then, within extracted & subdirs, list all the files to be converted
  FileUtils.cd extracted
  files_to_convert = []
  Find.find("."){|found|
    found_base = File.basename(found)
    if (!!(found_base =~ /\.(gff3*|sam|wig|gr|bed)$/ )) & !(found_base =~ /^\./) then
      files_to_convert.push found
    end
  }
  # Didn't find any
  next if files_to_convert.empty?
 
  # Recursively make each file's containing folders inside ws210 and copy them
  files_to_convert.each{|localpath|
    # Get the size
    currSize = File.size?(localpath)
    total_size += currSize ? currSize : 0
    puts "#{convert_size currSize} bytes for #{localpath}"
  }

}
puts "total was #{convert_size(total_size)}"

