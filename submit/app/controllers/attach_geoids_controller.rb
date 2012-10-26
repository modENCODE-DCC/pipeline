class AttachGeoidsController < CommandController
include GeoidHelper
require 'ftools'
  
  # Filename constants
  NEW_SDRF_SUFFIX = "_withGeoids"

  def initialize(options)
    super
    return unless options[:command].nil?
    self.command_object = AttachGeoids.new(options)
    # Construct command
    basedir = ExpandController.path_to_project_dir(Project.find(self.command_object.project_id))
    extracted = File.join(basedir, "extracted")
    sdrf = find_sdrf(extracted)
    if sdrf.nil? then
      self.command_object = nil
      return
    end
    # Make a copy of the sdrf to update
    new_sdrf = "#{sdrf}#{AttachGeoidsController::NEW_SDRF_SUFFIX}"
    begin
      File.copy(sdrf, new_sdrf)
    rescue Exception => e
      logger.error "Couldn't copy #{sdrf} to #{new_sdrf}!"
      self.command_object = nil
      return
    end
    sdrf_dir = File.dirname new_sdrf

    command = "#{
                options[:project_id]}\t#{
                options[:gse]}\t#{
                options[:gsms]}\t#{
                options[:geo_column]}\t#{
                new_sdrf} to #{sdrf_dir}"
    # write the command string
    self.command_object.command = command
    # Whether to immediately run the database command or not.
    command_object.creating = options[:creating]
    command_object.attaching = options[:attaching]
    self.command_object.save
  end

  # Returns the path to the SDRF file, given the extracted dir
  # Based on the find-idf code in validate_idf2chadoxml controller.
  # But better.
  def find_sdrf(extracted)
    # If there's nothing but a folder in the extracted dir, assume it's in there.
    # Otherwise, just check extracted dir.
    lookup_dir = extracted
    entry =  Dir.glob(File.join(lookup_dir, "*")).reject{|f| f =~ /\.chadoxml$|\/ws\d+$/ }
    if (entry.size == 1) && File.directory?(entry.first) then
      lookup_dir = entry.first
    end

    possible_sdrfs = Dir.glob(File.join(lookup_dir, "*[sS][dD][rR][fF]*")) # full path
    # ignore ._ files and an already-copied sdrf
    possible_sdrfs.reject!{|f| ( f =~ /^\._/ ) || ( f.include? AttachGeoidsController::NEW_SDRF_SUFFIX ) }
    unless possible_sdrfs.length == 1 then
      logger.error "Found #{possible_sdrfs.length} sdrf files in #{lookup_dir}; there can be only one."
      return nil
    end
    possible_sdrfs.first
  end
 
  # Creates an archive containing the new version of the sdrf
  # takes full path to sdrf
  def make_archive(archivename, archive_comment, sdrf)
    project_dir = ExpandController.path_to_project_dir(command_object.project)
    extracted_dir = File.join(project_dir, "extracted")
    relative_sdrf = sdrf.sub(extracted_dir, "")
    relative_sdrf.gsub!(/^\/*/, '') # remove leading /s
    
    # Find existing active archives made for sdrf storage
    old_archives = command_object.project.project_archives.find_all{|pa| 
      (pa.status == ProjectArchive::Status::EXPANDED) && (pa.is_active) &&
      (pa.file_name.include? archivename)
    }
    # Deactivate them and remove any of their project files
    old_archives.each{|pa| 
      pa.status = ProjectArchive::Status::NOT_EXPANDED
      pa.is_active = false
      pa.save
      pa.project_files.each{|pf|
        pf.destroy
      }
    }
    # If there are still any matching ProjectFiles, eg from original archive
    old_sdrf_files = []
    command_object.project.project_archives.each{|pa|
      found = pa.project_files.find_by_file_name(relative_sdrf) 
      old_sdrf_files << found unless found.nil?
    }
    # Mark them as overwritten
    old_sdrf_files.each{|os|
      os.is_overwritten = true
      os.save
    }
    # Then make the new archive
    (archive = command_object.project.project_archives.new).save
    tarname = "#{"%03d" % archive.attributes[archive.position_column]}_#{archivename}.tar"
    archive.file_name = "#{tarname}.gz"
    archive.file_date = Time.now
    archive.is_active = true
    archive.comment = archive_comment 
    archive.save

    # And tar it up -- slightly modified from url_upload_replacement_controller
    escape_quote = "'\\''"
    absolute_desttgz = File.join(project_dir, archive.file_name)
    cmd = "tar -czvf '#{absolute_desttgz.gsub(/'/, escape_quote)}'  -C '#{extracted_dir.gsub(/'/, escape_quote)}' #{relative_sdrf.gsub(/'/, escape_quote)}"
 
    # TODO: error handling
    result = `#{cmd} 2>&1`
    command_object.stdout = "#{command_object.stdout}\nCompressed #{result} to #{File.basename(absolute_desttgz)}"
    command_object.save

    # Finish updating the archive
    archive.file_size = File.size(absolute_desttgz)
    archive.signature = PipelineController.new.generate_file_signature(absolute_desttgz)
    archive.status = ProjectArchive::Status::EXPANDED
    archive.save

    # Then make the new ProjectFile for the sdrf
    (project_file = archive.project_files.new(
      :file_name => relative_sdrf,
      :file_size => File.size(sdrf),
      :file_date => File.ctime(sdrf),
      :signature => PipelineController.new.generate_file_signature(sdrf)
    )).save
  end

  
  # Copys from_sdrf to to_sdrf, failing the 
  # command if there is a problem
  def sdrf_copy(from_sdrf, to_sdrf)
    begin
      File.copy(from_sdrf, to_sdrf)
    rescue Exception => e
      command_object.stderr = "#{command_object.stderr}\nCouldn't make a copy of sdrf file: #{e}"
      command_object.status = AttachGeoids::Status::ATTACH_FAILED
      command_object.save
      return false
    end
    true
  end
  
  # Removes a temporary sdrf that was created with new geoids, if one exists
  def delete_temp_sdrf
    (geoid_string, output_dir) = command_object.command.split(/ to /)
    (pid, gse, gsms, sdrf) = geoid_string.split(/\t/)
    begin
      File.delete sdrf
    rescue Exception => e
      # Complain, but don't fail the command
      command_object.stderr = "#{command_object.stderr}\nFailed to delete temporary file#{sdrf}: #{e}. " +
        "\nYou may manually delete it."
    end
  end
  
  def run
    super do
      (geoid_string, output_dir) = command_object.command.split(/ to /)
      # Also get path to sdrf for later and column if provided
      (pid, gse, gsms, protocol_col, sdrf) = geoid_string.split(/\t/)

      # Run the appropriate helper -- are we creating a geoid.marshal or applying it?
      if command_object.creating then
        params = {:run_batch => false,
                  :geoid_string => geoid_string,
                  :output_dir => output_dir,
                  :calling_command => command_object
                 }
        # If attaching, also commit to DB
        params[:no_db_commits] = command_object.attaching ? false : true
        
        command_object.stdout = "#{command_object.stdout}\nCreating new sdrf and GEOid marshal file..."

        # Heavy lifting here, from GeoidHelper
        begin
          attached_geoids = find_replicates(params)
        rescue Exception => e
          # Something broke! Fail the command!
          # get the line info too :
          lineno = e.backtrace[0].split(":")[-2]
          command_object.stderr = "#{command_object.stderr}\nError in find_replicates(#{lineno}): #{e}"
          command_object.status = AttachGeoids::Status::CREATE_FAILED
          command_object.save
          return true # Should be false, but that'd affect Project's status which'd be bad
        end

        command_object.stdout = "#{command_object.stdout}\nFinished creating sdrf and marshal files!"
      
      elsif command_object.attaching then # Attaching GeoIDs from a preexisting marshal file to the database
        marshal_file = File.join(output_dir, GEOID_MARSHAL)

        command_object.stdout = "#{command_object.stdout}\nExtracting GEOids from marshal file & attaching to database..."
        # Heavy lifting - in GeoidHelper. We are committing to DB.
        begin
          attached_geoids = update_db(marshal_file, false)
        rescue Exception => e
          lineno = e.backtrace[0]
           # Something broke! Fail the command!
          command_object.stderr = "#{command_object.stderr}\nError in update_db(#{lineno}): #{e}"
          command_object.status = AttachGeoids::Status::ATTACH_FAILED
          command_object.save
          return true # Should be false, but that'd affect Project's status which'd be bad
        end
        if attached_geoids.nil? then 
          # It didn't crash, but it seems to have failed.
          command_object.stderr = "#{command_object.stderr}\nupdate_db did not appear to attach any geoids! Failing!"
          command_object.status = AttachGeoids::Status::ATTACH_FAILED
          command_object.save
          return true
        end
        command_object.stdout = "#{command_object.stdout}\nFinished attaching GEOids to database!"
      else
        # neither creating nor attaching - complain mildly & die.
        command_object.stderr = "#{command_object.stderr}\nGeoids were neither created nor attached -- completing command."
        command_object.status = AttachGeoids::Status::CREATE_FAILED
        command_object.save
        return true # Failure, so should be false, but don't want to change project's status.
      end
   
      # Then, if geoids were attached to db, replace the SDRF with the new one & make TrackTags
      if command_object.attaching then
        
        command_object.stdout = "#{command_object.stdout}\nSaving the new sdrf in an archive..."
        
        orig_sdrf = sdrf.sub(AttachGeoidsController::NEW_SDRF_SUFFIX, "")
        return true unless sdrf_copy(sdrf, orig_sdrf)
        make_archive("sdrf_with_attached_GEOids", "Archive of sdrf with GEO ids that were manually attached.", orig_sdrf)
        
        # Then, delete the extra sdrf copy
        delete_temp_sdrf()
                
        # TrackTags
        command_object.stdout = "#{command_object.stdout}\nUpdating track tags with new GEOids..."
        # Search for existing track tags
        old_geoid_tts = TrackTag.find_all_by_project_id_and_cvterm(command_object.project.id, "GEO_record")
        old_geoid_tts += TrackTag.find_all_by_project_id_and_cvterm(command_object.project.id, "data_url").find_all { |tt| tt.name =~ /^GSE|^GSM/ }
        
        old_geoids = old_geoid_tts.map{|tt| tt.name}

        if old_geoid_tts.empty? then
          # Set up TrackTag info
          tracks = TrackTag.find_all_by_project_id(command_object.project.id).map{|tt| tt.track}.uniq
          experiment_id = TrackTag.find_by_project_id(command_object.project_id).experiment_id
          history_depth = 1
        else
          # Use the existing geoids as a template
          tracks = old_geoid_tts.map{|tt| tt.track}.uniq
          experiment_id = old_geoid_tts.first.experiment_id
          history_depth = old_geoid_tts.first.history_depth
        end 
        cvterm = "GEO_record"
        project_id = command_object.project.id

        # Then create TrackTags -- attach each geoid to each track
        begin
          attached_geoids.uniq.product(tracks).each{|geoid, tracknum| 
            TrackTag.new(
              :experiment_id => experiment_id,
              :name => geoid,
              :project_id => project_id,
              :track => tracknum,
              :value => geoid, 
              :cvterm => cvterm,
              :history_depth => history_depth
            ).save
          }
        rescue Exception => e
          command_object.stderr = "#{command_object.stderr}\nFailed to create TrackTags: #{e}"
          command_object.status = AttachGeoids::Status::ATTACH_FAILED
          command_object.save
        end
        # Then destroy existing track tags, if any -- attempt this even if new tts failed to create
        begin
          old_geoid_tts.each{|old| old.destroy }
        rescue Exception => e
          command_object.stderr = "#{command_object.stderr}\nFailed to destroy outdated TrackTags: #{e}"
          command_object.status = AttachGeoids::Status::ATTACH_FAILED
          command_object.save
        end
        return true if command_object.status == AttachGeoids::Status::ATTACH_FAILED
      end
      

      # If it got this far, it looks like it worked - update status and save
      if command_object.attaching then # Created and attached geoids
        command_object.stdout = "#{command_object.stdout}\nFinished!"
        command_object.status = AttachGeoids::Status::ATTACHED
      else # Just created geoids
        command_object.status = AttachGeoids::Status::CREATED
      end
      command_object.save 
    end
  end

end
