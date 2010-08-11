#!/usr/bin/ruby
# It is recommended to run this as sudo -u www-data or whatever the rails user actually is.

# GenerateDuplicatesReport
# This will create a list of all ProjectFiles and ProjectArchives which are
# duplicates going by the signatures they have.
# It will ignore files for which the signature is nil.
#
# PLEASE NOTE: It will also ignore ProjectFiles and ProjectArchives which are
# not associated with a Project!
#
require File.dirname(__FILE__) + '/../config/environment'
system("/usr/bin/renice", "15", "#{$$}")
starttime = Time.now

if ARGV.empty? then
  puts "Usage: sudo -u www-data ruby GenerateDuplicatesReport.rb [output filename]"
  exit
end

report_file = File.open(ARGV[0], 'w')

report_file.puts "Pipeline -- Duplicate Files Found\n"
report_file.puts Time.now
report_file.puts "\n(Scroll to bottom for summary of the duplicates found.)\n"
report_file.puts "Full list of duplicate files found:\n"

projects_with_dupes = []

def list_dupes(project, duplicates, report_file)
  report_file.puts "Project #{project.id} (#{project.name}): "
  duplicates.each{|file, matchlist|
    report_file.puts "  #{file.class.name} #{file.id} (#{file.file_name}) matches:"
    matchlist.each{|matchproj, match|
      next if match == file
      report_file.puts "    #{match.class.name} #{match.id} (#{match.file_name}) in project #{matchproj}"
    }
  }
  report_file.puts "\n"
end

Project.all.each{|proj|
  matches = PipelineController.new.get_matching_files(proj)
  unless matches.empty? then
    list_dupes(proj, matches, report_file)
  projects_with_dupes.push(proj.id)
  end
}

report_file.puts "Summary: A total of #{projects_with_dupes.length} projects were "+
  "associated with duplicate ProjectFiles or ProjectArchives. The projects found
  were: "

projects_with_dupes.each{|pwd| report_file.puts pwd }

elapsedtime = Time.now - starttime

report_file.puts "This report took #{elapsedtime} seconds to generate."

report_file.close

