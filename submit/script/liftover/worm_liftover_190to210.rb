#!/usr/bin/ruby
require File.dirname(__FILE__) + "/../../config/environment"
require 'find'
require 'fileutils'
# You should run this with sudo -u www-data

# Change the versions we are lifting here!
LIFTOVER_SRC_VER = "190"
LIFTOVER_DEST_VER = "210"

# PATH_TO_LIFTOVER - the absolute path to the folder containing the liftover &
# picard files. Right now it's defined as "the folder this script is in".
PATH_TO_LIFTOVER = File.expand_path File.dirname(__FILE__)

LIFTOVER_BASE_CMD = "java -cp #{PATH_TO_LIFTOVER}/liftover/bin/" +
  ":#{PATH_TO_LIFTOVER}/picard/bin/:#{PATH_TO_LIFTOVER}/liftover/lib/" +
  "JSAP-2.1.jar org.modencode.tools.liftover.Liftover" 


puts "Liftover worm files from WS#{LIFTOVER_SRC_VER} to ws#{LIFTOVER_DEST_VER}"

# Copied from public_controller because the original is private.
def organisms_by_pi
  if File.exists? "#{RAILS_ROOT}/config/pi_organisms.yml" then
    open("#{RAILS_ROOT}/config/pi_organisms.yml") { |f| YAML.load(f.read) }
  else
    {}
  end
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
 
  puts "#{foundproj.id} found extracted in worm project!"
  
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

  # Create WS210 (or whatever) folder. If there's one there already, complain.
  ws210 = File.join(extracted, "ws#{LIFTOVER_DEST_VER}")
  if File.exist? ws210 then
    puts "ws210 folder already exists at #{ws210} !"
    next
  end
  FileUtils.mkdir(ws210)
  
  # Recursively make each file's containing folders inside ws210 and copy them
  files_to_convert.each{|localpath|
    nested_dirs = localpath.split("/")
    file_to_copy = nested_dirs.pop
    path_to_new = ws210
    nested_dirs.each{|current_dir|
      path_to_new = File.join(path_to_new, current_dir)
      FileUtils.mkdir path_to_new unless File.directory? path_to_new
    }

    # Then, run the liftover right into the new folder
    input_path = localpath
    dest_path = File.join(path_to_new, file_to_copy)
    filetype =  case File.extname file_to_copy
      when ".gff", ".gff3"
        " -g "
      when ".sam"
        " -s "
      when ".wig", ".gr"
        " -w "
      when ".bed"
        " -b "
      else
        " -x " # IE, bad extension name, somehow.
    end
    
    liftover_cmd = LIFTOVER_BASE_CMD + filetype + input_path + " -1 " +
      LIFTOVER_SRC_VER +  " -2 " + LIFTOVER_DEST_VER + " -o " +  dest_path
  puts liftover_cmd
  system(liftover_cmd)
  }

 # Then, create a new project_archive & attach it to a tar of ws210
  liftover_archive_name = "Files_lifted_to_WS#{LIFTOVER_DEST_VER}.tar.gz"
 (liftover_archive = foundproj.project_archives.new).save 
  liftover_archive.file_name = "#{"%03d" % liftover_archive.attributes[
    liftover_archive.position_column]}_#{liftover_archive_name}"
  liftover_archive.file_date = Time.now
  liftover_archive.is_active = false 
  liftover_archive.comment = "Contains files lifted to ws#{LIFTOVER_DEST_VER}" +
    " from ws#{LIFTOVER_SRC_VER}"
  liftover_archive.save

  # Make the tarball and attach it - we're in the extracted dir, so store it
  # in .. instead; use relative path /ws210 so it nests appropriately
  # 
  tarball_cmd = "tar -cvzf ../#{liftover_archive.file_name} " +
    "ws#{LIFTOVER_DEST_VER}"
  puts tarball_cmd
  system(tarball_cmd)

  # Then, attach more info to the projectArchive as necessary
  liftover_archive.file_size = File.size("../#{liftover_archive.file_name}")
  liftover_archive.status = ProjectArchive::Status::NOT_EXPANDED
  liftover_archive.signature = PipelineController.new.generate_file_signature(
    "../#{liftover_archive.file_name}")
  liftover_archive.save
}
