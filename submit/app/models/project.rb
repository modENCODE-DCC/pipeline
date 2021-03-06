class Project < ActiveRecord::Base

  belongs_to :user
  belongs_to :project_type
  belongs_to :group
  has_many :project_archives, :dependent => :destroy, :order => :archive_no
  has_many :commands, :dependent => :destroy, :order => :position
  has_many :track_tags, :dependent => :destroy
  has_many :track_stanzas, :dependent => :destroy
  has_many :comments, :dependent => :destroy, :order => :created_at
  belongs_to :deprecated_by_project, :class_name => Project.name, :foreign_key => :deprecated_project_id
  belongs_to :superseded_by_project, :class_name => Project.name, :foreign_key => :superseded_project_id

  validates_presence_of :name
  validates_presence_of :project_type_id
  validates_presence_of :status
  validates_presence_of :user_id
  validates_uniqueness_of   :name, :unless => Proc.new { |project| project.deprecated? || project.superseded? }, :scope => :deprecated_project_id

  # Helper accessors
  def deprecated?
    !self.deprecated_project_id.nil?
  end
  def superseded?
    !self.superseded_project_id.nil?
  end
  def retracted?
    self.deprecated_project_id == 0
  end
  def released?
    self.status == Project::Status::RELEASED
  end
  def released_with_reservations?
    self.released? && !self.commands.all.find { |cmd| cmd.is_a?(ReleaseWithReservations) }.nil?
  end

  def report_generated?
    if Project::Status::ok_next_states(self).include?(Project::Status::REPORTING) then
      cmd = self.commands.all.find_all { |cmd| cmd.is_a?(Report) }.sort { |up1, up2| up1.end_time.to_i <=> up2.end_time.to_i }.last
      return true if self.report_tarball_generated? || self.reported?
      return cmd.status == Project::Status::REPORT_GENERATED unless cmd.nil?
    end
  end
  def report_tarball_generated?
    if Project::Status::ok_next_states(self).include?(Project::Status::REPORTING) then
      cmd = self.commands.all.find_all { |cmd| cmd.is_a?(Report) }.sort { |up1, up2| up1.end_time.to_i <=> up2.end_time.to_i }.last
      return true if self.reported?
      return cmd.status == Project::Status::REPORT_TARBALL_GENERATED unless cmd.nil?
    end
  end
  def reported?
    if Project::Status::ok_next_states(self).include?(Project::Status::REPORTING) then
      cmd = self.commands.all.find_all { |cmd| cmd.is_a?(Report) }.sort { |up1, up2| up1.end_time.to_i <=> up2.end_time.to_i }.last
      return cmd.status == Project::Status::REPORTED unless cmd.nil?
    end
  end

  def has_readme?
    return (self.readme_project_file == false) ? false : true
  end
  def readme_project_file
    return @pf unless @pf.nil?
    #the readme file must have the name README
    files = self.project_archives.find_all_by_is_active(true).map { |pa| pa.project_files }.flatten
    return false unless files.size > 0

    # Is everything contained in a subdirectory?
    if files.find { |f| f.file_name !~ /\// } then
      # No, there are files in the root
      @pf = files.find { |f| f.file_name =~ /^README(.txt)?$/ }
    else
      # No files in the root, what's the base dir?
      root_dir = files.first.file_name
      while ((root_dir = File.dirname(root_dir)) =~ /\//); 1; end
      @pf = files.find { |f| f.file_name =~ Regexp.new("^#{Regexp.escape(File.join(root_dir, "README"))}(.txt)?$") }
    end
    @pf = false if @pf.nil?
    return @pf
  end

  def readme
    pf = self.readme_project_file
    return nil if pf == false
    path = File.join(PipelineController.new.path_to_project_dir(pf.project_archive.project), "extracted", pf.file_name)
    if File.exists?(path) then
      return File.read(path)
    else
      return "Readme not extracted!"
    end
  end

  def has_preview?
    path = File.join(PipelineController.new.path_to_project_dir(self), "browser", "#{self.id}.conf")
    return File.exist?(path)
  end

  def released_organism
    tt = TrackTag.find_by_project_id_and_cvterm(self.id, "organism")
    return tt.value if tt
  end

  def has_raw_data?
    file_types = [".cel", ".pair", ".txt", ".fasta", ".fastq"]
    file_extensions = self.project_archives.find_all_by_is_active(true).map { |pa| pa.project_files }.flatten.map { |pf| File.extname(pf.file_name).downcase }.uniq.reject { |ext| ext == "" }
    # If there's any intersection (&), then there must be one of file_types in file_extensions
    return (file_extensions & file_types).size > 0 ? true : false
  end

  def has_wig_data?
    #assuming signal data is of type wig/bed with those filenames
    file_types = [".wig", ".bed", ".gr", ".sgr"]
    file_extensions = self.project_archives.find_all_by_is_active(true).map { |pa| pa.project_files }.flatten.map { |pf| File.extname(pf.file_name).downcase }.uniq.reject { |ext| ext == "" }
    # If there's any intersection (&), then there must be one of file_types in file_extensions
    return (file_extensions & file_types).size > 0 ? true : false
  end

  def has_metadata?
    #assuming metadata is labeled with "idf" and "sdrf" in filename
    if (@has_metadata.nil?) then
      file_names = ProjectFile.find_by_sql("SELECT pf1.* FROM project_files pf1 INNER JOIN project_archives pa ON pf1.project_archive_id = pa.id INNER JOIN project_files pf2 ON pf2.project_archive_id = pa.id WHERE pa.project_id = #{self.id} AND pa.is_active = true AND position('sdrf' in lower(pf1.file_name)) > 0 AND position('idf' in lower(pf2.file_name)) > 0 LIMIT 1")
      @has_metadata = (file_names.size > 0)
    end
    return @has_metadata
  end

  def has_feature_data?
    #assuming feature data has gff or gff3 extension
    file_types = [".gff"]
    file_extensions = ProjectArchive.find_all_by_project_id_and_is_active(self.id, true).map { |pa| pa.project_files }.flatten.map { |pf| File.extname(pf.file_name).downcase }.uniq.reject { |ext| ext == "" }
    # If there's any intersection (&), then there must be one of file_types in file_extensions
    return (file_extensions & file_types).size > 0 ? true : false
  end

  def has_geo_update?
    # Have geoids been successfully attached to this project
    attached = commands.find_by_status(AttachGeoids::Status::ATTACHED)
    return ! attached.nil?
  end
  
  def has_config?
    #TODO: fixme
    return true
  end

  def level
    # uploaded raw data files incl readme = level 1
    # uploaded wig/alignment/feature files = level 2
    # only once released  = level 3
    if (@level.nil?) then
      if self.released?
        @level = 3
      elsif ((self.has_wig_data? || self.has_feature_data?) && (self.has_readme? || self.has_metadata?))
        @level = 2  # TODO: need to add in a self.has_config?
      elsif (self.has_raw_data? && (self.has_readme? || self.has_metadata?))
        @level = 1
      elsif self.status == Project::Status::NEW
        @level = 0  
      else
        @level = 0
      end
    end
    @level
  end

  def release_date
    return nil unless self.released?
    last_release = self.commands.all.find_all { |cmd| cmd.is_a?(Release) && cmd.succeeded? }.sort { |up1, up2| up1.end_time.to_i <=> up2.end_time.to_i }.last
    return self.updated_at if last_release.nil?
    return last_release.end_time.nil? ? last_release.updated_at : last_release.end_time
  end

  def most_recent_upload_date
    last_upload = self.commands.find_all { |cmd| cmd.is_a?(Upload) && cmd.succeeded? }.sort { |up1, up2| up1.end_time.to_i <=> up2.end_time.to_i }.last
    return nil if last_upload.nil?
    return last_upload.end_time.nil? ? last_upload.updated_at.to_date : last_upload.end_time.to_date
  end
  def embargo_start_date
    # Special case for legacy projects released before 2009-02-01
    return self.release_date.to_date if (!self.release_date.nil? && self.release_date.to_date < Date.new(2009, 02, 01))

    # Find first upload date
    first_upload = self.commands.all.find_all { |cmd| cmd.is_a?(Upload) && cmd.succeeded? }.sort { |up1, up2| up1.end_time.to_i <=> up2.end_time.to_i }.first
    return nil if first_upload.nil?
    upload_date = first_upload.end_time.nil? ? first_upload.updated_at.to_date : first_upload.end_time.to_date
  end
  def embargo_end_date
    start = self.embargo_start_date
    return nil if start.nil?
    end_date = start.>>(9)
    if start.day > end_date.day then
      # If it was on the 31st, and got pushed to the 30th (or 28th/29th), then jump to the 1st of the next month
      end_date = Date.new(end_date.year, end_date.month, 1)
      end_date = end_date.>> 1
    end

    return end_date
  end

  def same_pi?(other_lab)
    return false if other_lab.nil?
    return true if self.lab == other_lab
    return true if self.pi == other_lab
    pis = Hash.new
    if File.exists? "#{RAILS_ROOT}/config/PIs.yml" then
      pis = [ open("#{RAILS_ROOT}/config/PIs.yml") { |f| YAML.load(f.read) } ]
      pis = pis.first unless pis.nil?
    end
    pis = Hash.new if pis.nil?
    other_pis = pis[other_lab] ? [ other_lab ] : pis.find_all { |k, v| v.include?(other_lab) }.map { |k, v| k }
    return other_pis.include?(self.pi)
  end

  def last_command_not_failed
    return self.commands.reject { |cmd| Project::Status::is_failed_state(cmd.status) }.last
  end
  module Status
    include Command::Status
    include Upload::Status
    include Expand::Status
    include Validate::Status
    include Load::Status
    include Unload::Status
    include FindTracks::Status
    include Release::Status
    include Publish::Status
    include Delete::Status
    include Report::Status
    include PreviewBrowser::Status
    include Liftover::Status
    # Status constants
    NEW = "new"
    CONFIGURING = "configuring tracks"
    CONFIGURED = "tracks configured"


    DELETED = "deleted" #i don't know if this is necessary
    FLAGGED = "flagged" #this could be useful for signaling between DCC and groups

    def self.states_in_order
      {
        0 => [
          PAUSED, QUEUED, FLAGGED, CANCELING, CANCELED, 
          FAILED, DELETING, DELETED, DELETE_FAILED
        ],
        1 => [NEW, UPLOADING, UPLOAD_FAILED],
        2 => [UPLOADED, EXPANDING, EXPAND_FAILED, LIFTED, GENERATING_PREVIEW, PREVIEW_FAILED],
        3 => [EXPANDED, VALIDATING, VALIDATION_FAILED, LIFTING, LIFTOVER_FAILED, PREVIEW_GENERATED],
        4 => [VALIDATED, LOADING, LOAD_FAILED, UNLOADING, UNLOADED, UNLOAD_FAILED],
        5 => [LOADED, FINDING, FINDING_FAILED],
        6 => [FOUND, CONFIGURING],
        7 => [CONFIGURED, REPORTING, REPORTED, REPORT_GENERATED, REPORT_TARBALL_GENERATED, REPORTING_FAILED, AWAITING_RELEASE, RELEASE_REJECTED, DCC_RELEASED, USER_RELEASED],
        8 => [RELEASED, PUBLISHING],
        9 => [PUBLISHED]
      }
    end

    def self.status_number(state)
      states = states_in_order.find { |n, states| states.include?(state) }
      if states then
        states[0]
      else
        nil
      end
    end

    def self.active_states
      [
        Delete::Status::DELETING,
        Load::Status::LOADING,
        Expand::Status::EXPANDING,
        Release::Status::AWAITING_RELEASE,
        Unload::Status::UNLOADING,
        Upload::Status::UPLOADING,
        Validate::Status::VALIDATING,
        FindTracks::Status::FINDING,
        Report::Status::REPORTING,
        PreviewBrowser::Status::GENERATING_PREVIEW,
        Liftover::Status::LIFTING,
      ]
    end
    def self.is_active_state(state)
      return self.active_states.include?(state)
    end

    def self.is_failed_state(state)
      failed_states = [
        Upload::Status::UPLOAD_FAILED,
        Expand::Status::EXPAND_FAILED,
        Validate::Status::VALIDATION_FAILED,
        Load::Status::LOAD_FAILED,
        FindTracks::Status::FINDING_FAILED,
        Release::Status::RELEASE_REJECTED,
        Delete::Status::DELETE_FAILED,
        Unload::Status::UNLOAD_FAILED,
        Report::Status::REPORTING_FAILED,
        PreviewBrowser::Status::PREVIEW_FAILED,
        Liftover::Status::LIFTOVER_FAILED,
      ]
      return failed_states.include?(state)
    end

    def self.is_succeeded_state(state)
      failed_states = [
        Upload::Status::UPLOADED,
        Expand::Status::EXPANDED,
        Validate::Status::VALIDATED,
        Load::Status::LOADED,
        FindTracks::Status::FOUND,
        Release::Status::RELEASED,
        Delete::Status::DELETED,
        Unload::Status::UNLOADED,
        Report::Status::REPORTED,
        Report::Status::REPORT_TARBALL_GENERATED,
        Report::Status::REPORT_GENERATED,
        PreviewBrowser::Status::PREVIEW_GENERATED,
        Liftover::Status::LIFTED,
      ]
      return failed_states.include?(state)
    end

    def Status.state_position(project)
      state = project.is_a?(Project) ? project.status : project
      ordered_status = [
        Project::Status::CANCELING, Project::Status::CANCELED, Project::Status::FLAGGED, Project::Status::NEW, Project::Status::FAILED,
        Project::Status::UPLOADING, Project::Status::UPLOAD_FAILED, Project::Status::UPLOADED, 
        Project::Status::LIFTED,  Project::Status::EXPANDING,
        Project::Status::EXPAND_FAILED, Project::Status::EXPANDED, Project::Status::VALIDATING,
        Project::Status::LIFTING, Project::Status::VALIDATION_FAILED, Project::Status::LIFTOVER_FAILED,
        Project::Status::VALIDATED, Project::Status::LOADING, Project::Status::LOAD_FAILED, Project::Status::LOADED,
        Project::Status::UNLOADING, Project::Status::UNLOAD_FAILED, Project::Status::UNLOADED, Project::Status::FINDING,
        Project::Status::FINDING_FAILED, Project::Status::FOUND, Project::Status::CONFIGURING, Project::Status::CONFIGURED,
        Project::Status::AWAITING_RELEASE, Project::Status::RELEASE_REJECTED, Project::Status::USER_RELEASED, Project::Status::DCC_RELEASED,
        Project::Status::RELEASED, Project::Status::REPORT_GENERATED, Project::Status::REPORT_TARBALL_GENERATED, Project::Status::REPORTED, 
        Project::Status::QUEUED, Project::Status::PAUSED, Project::Status::DELETING, Project::Status::DELETE_FAILED, Project::Status::DELETED 
      ]
      pos = ordered_status.index(state)
      pos.nil? ? 0 : pos
    end

    def Status.ok_next_states(project)
      state = project.status
      ok = Array.new
      case state
      when NEW
        ok = [ DELETING, UPLOADING ]
      when UPLOAD_FAILED
        ok = [ DELETING, UPLOADING ]
        ok.push VALIDATING if project.project_archives.find_all { |pa| pa.is_active }.size > 0
      when UNLOADED
        ok = [ DELETING, UPLOADING ]
        ok.push VALIDATING if project.project_archives.find_all { |pa| pa.is_active }.size > 0
      when UPLOADED
        ok = [ UPLOADING, DELETING, VALIDATING ]
      when EXPAND_FAILED
        ok = [ UPLOADING, DELETING, VALIDATING ]
      when EXPANDED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, LIFTING, VALIDATING ]
      when LIFTED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING ]
      when LIFTOVER_FAILED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING  ]
      when VALIDATION_FAILED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING ]
      when VALIDATED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING, LOADING ]
      when LOAD_FAILED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING, LOADING ]
      when LOADED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING, LOADING, FINDING ]
      when FINDING_FAILED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING, LOADING, FINDING ]
      when FOUND
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING, LOADING, FINDING, CONFIGURING ]
      when CONFIGURED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING, LOADING, FINDING, CONFIGURING, REPORTING, AWAITING_RELEASE ]
      when AWAITING_RELEASE
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING, LOADING, FINDING, CONFIGURING, REPORTING, AWAITING_RELEASE ]
      when REPORTING_FAILED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING, LOADING, FINDING, CONFIGURING, REPORTING, AWAITING_RELEASE ]
      when REPORT_GENERATED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING, LOADING, FINDING, CONFIGURING, REPORTING, AWAITING_RELEASE ]
      when REPORT_TARBALL_GENERATED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING, LOADING, FINDING, CONFIGURING, REPORTING, AWAITING_RELEASE ]
      when REPORTED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING, LOADING, FINDING, CONFIGURING, REPORTING, AWAITING_RELEASE ]
      when USER_RELEASED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING, LOADING, FINDING, CONFIGURING, REPORTING, AWAITING_RELEASE ]
      when DCC_RELEASED
        ok = [ UPLOADING, DELETING, GENERATING_PREVIEW, VALIDATING, LOADING, FINDING, CONFIGURING, REPORTING, AWAITING_RELEASE ]
      when RELEASED
        ok = [ PUBLISHING ]
      when RELEASE_REJECTED
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING, FINDING, CONFIGURING, REPORTING, AWAITING_RELEASE ]
      when FAILED
        ok = [ UPLOADING, DELETING ]
        ok.push VALIDATING if project.project_archives.find_all { |pa| pa.is_active }.size > 0
      end

      return ok.uniq
    end

  end

end
