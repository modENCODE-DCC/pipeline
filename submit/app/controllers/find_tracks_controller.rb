require 'track_finder'

class FindTracksController < CommandController
  def initialize(options)
    super
    return unless options[:command].nil? # Set in CommandController if :command is given
    logger.error "Can't find tracks without a user id" unless options[:user_id]
    logger.info "Creating new FindTracks object with #{options}"
    self.command_object = FindTracks.new(options)
    logger.info "Created object: #{self.command_object}"
    command_object.command = command_object.project.id
    command_object.save
  end

  def run
    super do
      command_object.status = FindTracks::Status::FINDING
      command_object.stdout = ""
      command_object.stderr = ""
      command_object.save

      track_finder = TrackFinder.new(command_object)

      schemas = track_finder.get_experiments
      schema = "modencode_experiment_#{command_object.project.id}"


      unless schemas[schema] then
        command_object.stderr = "Couldn't find the loaded experiment in the #{schema} schema in the database.\nTry validating or loading the project again."
        command_object.status = FindTracks::Status::FINDING_FAILED
        command_object.save
        return self.do_after
      end

      track_finder.search_path = schema + "_data"
      experiment_id = schemas[schema][0]

      tracks_dir = File.join(ExpandController.path_to_project_dir(command_object.project), "tracks/")
      Dir.mkdir(tracks_dir,0775) unless File.exists?(tracks_dir)
      track_finder.delete_tracks(command_object.project.id, tracks_dir)

      res = track_finder.generate_track_files_and_tags(experiment_id, command_object.project.id, tracks_dir)
      if res.nil? then
        command_object.status = FindTracks::Status::FINDING_FAILED
        command_object.save
        return self.do_after
      end
      track_finder.load_into_gbrowse(command_object.project.id, tracks_dir)

      command_object.status = FindTracks::Status::FOUND
      command_object.save

      return self.do_after
    end
  end

  def do_after(options = {})
    if self.status == FindTracks::Status::FINDING_FAILED then
      return false
    else
      return true
    end
  end

end
