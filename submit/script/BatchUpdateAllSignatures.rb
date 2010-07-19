#!/usr/bin/ruby
require 'digest/md5'
require File.dirname(__FILE__) + '/../config/environment'
require 'find'

system("/usr/bin/renice", "15", "#{$$}")

starttime = Time.now

BYTES_TO_MD5 = 50000000
basepath = File.expand_path("#{ActiveRecord::Base.configurations[RAILS_ENV]['upload']}")

# Update signatures of all project archives
num_archive_sigs = 0
ProjectArchive.all.each{|pa|
  
  # get file of archive
  archivefile = File.join(basepath, pa.project_id.to_s, pa.file_name)
  unless File.exist? archivefile then
    puts "#{pa.id} - This archive has no file #{archivefile} - skipping"
    archivesig = nil
  else
  archivesig = Digest::MD5.hexdigest(File.read(archivefile, BYTES_TO_MD5))
  num_archive_sigs += 1
  end
  pa.signature = archivesig
  pa.save
  puts "Archive #{pa.id}: added signature #{archivesig}" unless archivesig.nil?
  
}

# also do projectFiles

# ProjectFiles:
# file_name = full path to it starting from expanded folder
# if it's overwritten, don't do it!
num_file_sigs = 0
ProjectFile.all.each{|pf|
  filesig = nil
  if pf.is_overwritten then
    puts "#{pf.id} - this file is overwritten -- skipping"
  else
    filearchive = pf.project_archive
    if filearchive.nil? then
      puts "#{pf.id} is in archive #{pf.project_archive_id} but that archive's nil! skipping."
    else
      fileproject = filearchive.project
      if fileproject.nil? then
        puts "#{pf.id}'s archive is in project #{filearchive.project_id} but that project's nil! skipping."
      else
        filepath = File.join(basepath, fileproject.id.to_s, "extracted", pf.file_name)
        unless File.exists? filepath then
          puts "#{pf.id}'s file #{pf.file_name} can't be found in its project #{fileproject.id}! Skipping"
        else
          # the file is there! hurrah!
          filesig = Digest::MD5.hexdigest(File.read(filepath, BYTES_TO_MD5))
          num_file_sigs += 1
        end
     end
   end
 end
 
  pf.signature = filesig
  pf.save
  puts "File #{pf.id} (#{pf.file_name}): added signature #{filesig}" unless filesig.nil?

}
elapsedtime = Time.now - starttime

puts "Generated signatures for #{num_archive_sigs} archives and #{num_file_sigs} files in #{elapsedtime} seconds."
