#!/usr/bin/ruby

# It is recommended to run this as sudo -u www-data or whatever the rails user actually is.
# Note that currently it skips anything that already has a signature
require 'digest/md5'
require File.dirname(__FILE__) + '/../config/environment'
require 'find'

system("/usr/bin/renice", "15", "#{$$}")

starttime = Time.now

BYTES_TO_MD5 = 50000000
basepath = File.expand_path("#{ActiveRecord::Base.configurations[RAILS_ENV]['upload']}")

# Update signatures of all project archives
num_archive_sigs = 0
skipped_archives = 0
ProjectArchive.all.each{|pa|
  # Optional - skip it if it already has a signature
  if pa.signature then
    puts ":#{pa.id} has sig #{pa.signature}"
    next
  end
  print "#{pa.id}: "
  # get file of archive
  archivefile = File.join(basepath, pa.project_id.to_s, pa.file_name)
  unless File.exist? archivefile then
    puts "#{pa.id} - This archive has no file #{archivefile} - skipping"
    archivesig = nil
    skipped_archives += 1
  else
  file_to_process = File.read(archivefile, BYTES_TO_MD5)
  if file_to_process.nil? then
    puts "#{pa.id} - File #{archivefile} exists but is empty - skipping"
    archivesig = nil
    skipped_archives += 1
  else
  	archivesig = Digest::MD5.hexdigest(file_to_process)
  	num_archive_sigs += 1
  end
  end
  pa.signature = archivesig
  pa.save
  puts "Archive #{pa.id}: added signature #{archivesig}" unless archivesig.nil?
  
}
# Because it crashed, skip the ones that already ran for better fasterness.
# This is optional and useful!
#already_ran = File.readlines("files_to_skip_for_batch")
#done_files = {}
#already_ran.each{|ar| done_files[ar.chomp.to_i] = true }


# also do projectFiles

# ProjectFiles:
# file_name = full path to it starting from expanded folder
# if it's overwritten, don't do it!
num_file_sigs = 0
skipped_files = 0
ProjectFile.all.each{|pf|
#  if done_files[pf.id] then
#    puts ":#{pf.id} already ran"
#    next
#  end
  # Optional - skip it if it already has a signature
  if pf.signature then
    puts ":#{pf.id} has sig #{pf.signature}"
    next
  end
  print "#{pf.id}: "
  filesig = nil
  if pf.is_overwritten then
    puts "#{pf.id} - this file is overwritten -- skipping"
    skipped_files += 1
  else
    filearchive = pf.project_archive
    if filearchive.nil? then
      puts "#{pf.id} is in archive #{pf.project_archive_id} but that archive's nil! skipping."
      skipped_files += 1  
    else
      fileproject = filearchive.project
      if fileproject.nil? then
        puts "#{pf.id}'s archive is in project #{filearchive.project_id} but that project's nil! skipping."
        skipped_files += 1
      else
        filepath = File.join(basepath, fileproject.id.to_s, "extracted", pf.file_name)
        unless File.exists? filepath then
          puts "#{pf.id}'s file #{pf.file_name} can't be found in its project #{fileproject.id}! Skipping"
          skipped_files += 1
        else
	  file_to_process = File.read(filepath, BYTES_TO_MD5)
          if file_to_process.nil? then
            puts "#{pf.id} - File #{filepath} exists but is empty - skipping"
            skipped_files += 1
          else  
            # the file is there! hurrah!
            filesig = Digest::MD5.hexdigest(File.read(filepath, BYTES_TO_MD5))
            num_file_sigs += 1
          end
        end
      end
    end
  end
 
  pf.signature = filesig
  pf.save
  puts "File #{pf.id} (#{pf.file_name}): added signature #{filesig}" unless filesig.nil?

}
elapsedtime = Time.now - starttime

puts "Generated signatures for #{num_archive_sigs} archives and #{num_file_sigs} files in #{elapsedtime} seconds. Skipped #{skipped_archives} archives and #{skipped_files} files."
