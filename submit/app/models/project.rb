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

  validates_presence_of :name
  validates_presence_of :project_type_id
  validates_presence_of :status
  validates_presence_of :user_id
  validates_uniqueness_of   :name, :unless => :deprecated?, :scope => :deprecated_project_id

  def deprecated?
    !self.deprecated_project_id.nil?
  end
  def released?
    self.status == Project::Status::RELEASED
  end
  def pi
    self.user.pi unless self.user.nil?
  end

  def has_readme?
    #the readme file must have the name README
    file_names = ProjectArchive.find_all_by_project_id(self.id).map{|a| ProjectFile.find_all_by_project_archive_id(a.id)}.flatten.map{|f| f.file_name}
    file_names.include?("README")
  end

  def has_raw_data?
    file_types = [".cel", ".pair", ".txt", ".fasta", ".fastq"]
    file_names = ProjectArchive.find_all_by_project_id(self.id).map{|a| ProjectFile.find_all_by_project_archive_id(a.id)}.flatten.map{|f| f.file_name.downcase}
    return file_types.map{|t| file_names.map{|n| n.include?(t)}}.flatten.include?(true)
  end

  def has_wig_data?
    #assuming signal data is of type wig/bed with those filenames
    file_types = [".wig", ".bed", ".gr", ".sgr"]
    file_names = ProjectArchive.find_all_by_project_id(self.id).map{|a| ProjectFile.find_all_by_project_archive_id(a.id)}.flatten.map{|f| f.file_name.downcase}
    return file_types.map{|t| file_names.map{|n| n.include?(t)}}.flatten.include?(true)
  end

  def has_metadata?
    #assuming metadata is labeled with "idf" and "sdrf" in filename
    has_idf = false
    has_sdrf = false
    file_names = ProjectArchive.find_all_by_project_id(self.id).map{|a| ProjectFile.find_all_by_project_archive_id(a.id)}.flatten.map{|f| f.file_name.downcase}
    has_idf = file_names.map{|t| t.include?("idf")}.flatten.include?(true)
    has_sdrf = file_names.map{|t| t.include?("sdrf")}.flatten.include?(true)
    return has_idf && has_sdrf
  end

  def has_feature_data?
    #assuming feature data has gff or gff3 extension
    file_types = [".gff"]
    file_names = ProjectArchive.find_all_by_project_id(self.id).map{|a| ProjectFile.find_all_by_project_archive_id(a.id)}.flatten.map{|f| f.file_name.downcase}
    return file_types.map{|t| file_names.map{|n| n.include?(t)}}.flatten.include?(true)
  end

  def has_config?
    #TODO: fixme
    return true
  end

  def level
    # uploaded raw data files incl readme = level 1
    # uploaded wig/alignment/feature files = level 2
    # only once released  = level 3
    if self.released?
      return 3
    elsif ((self.has_wig_data? || self.has_feature_data?) && (self.has_readme? || self.has_metadata?))
      return 2  # TODO: need to add in a self.has_config?
    elsif (self.has_raw_data? && (self.has_readme? || self.has_metadata?))
      return 1
    elsif self.status == Project::Status::NEW
      return 0  
    else
      return 0
    end
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
        2 => [UPLOADED, EXPANDING, EXPAND_FAILED],
        3 => [EXPANDED, VALIDATING, VALIDATION_FAILED],
        4 => [VALIDATED, LOADING, LOAD_FAILED, UNLOADING, UNLOADED, UNLOAD_FAILED],
        5 => [LOADED, FINDING, FINDING_FAILED],
        6 => [FOUND, CONFIGURING],
        7 => [CONFIGURED, AWAITING_RELEASE, RELEASE_REJECTED, DCC_RELEASED, USER_RELEASED],
        8 => [RELEASED, PUBLISHING],
        9 => [PUBLISHED]
      }
    end

    def self.status_number(state)
      states_in_order.find { |n, states| states.include?(state) }[0]
    end

    def self.is_active_state(state)
      active_states = [
        Delete::Status::DELETING,
        Load::Status::LOADING,
        Expand::Status::EXPANDING,
        Release::Status::AWAITING_RELEASE,
        Unload::Status::UNLOADING,
        Upload::Status::UPLOADING,
        Validate::Status::VALIDATING,
        FindTracks::Status::FINDING
      ]
      return active_states.include?(state)
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
      ]
      return failed_states.include?(state)
    end

    def Status.state_position(project)
      state = project.is_a?(Project) ? project.status : project
      ordered_status = [
        Project::Status::CANCELING, Project::Status::CANCELED, Project::Status::FLAGGED, Project::Status::NEW, Project::Status::FAILED,
        Project::Status::UPLOADING, Project::Status::UPLOAD_FAILED, Project::Status::UPLOADED, Project::Status::EXPANDING,
        Project::Status::EXPAND_FAILED, Project::Status::EXPANDED, Project::Status::VALIDATING, Project::Status::VALIDATION_FAILED,
        Project::Status::VALIDATED, Project::Status::LOADING, Project::Status::LOAD_FAILED, Project::Status::LOADED,
        Project::Status::UNLOADING, Project::Status::UNLOAD_FAILED, Project::Status::UNLOADED, Project::Status::FINDING,
        Project::Status::FINDING_FAILED, Project::Status::FOUND, Project::Status::CONFIGURING, Project::Status::CONFIGURED,
        Project::Status::AWAITING_RELEASE, Project::Status::RELEASE_REJECTED, Project::Status::USER_RELEASED, Project::Status::DCC_RELEASED,
        Project::Status::RELEASED, Project::Status::QUEUED, Project::Status::PAUSED, Project::Status::DELETING,
        Project::Status::DELETE_FAILED, Project::Status::DELETED 
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
        ok = [ UPLOADING, DELETING, VALIDATING ]
      when VALIDATION_FAILED
        ok = [ UPLOADING, DELETING, VALIDATING ]
      when VALIDATED
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING ]
      when LOAD_FAILED
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING ]
      when LOADED
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING, FINDING ]
      when FINDING_FAILED
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING, FINDING ]
      when FOUND
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING, FINDING, CONFIGURING ]
      when CONFIGURED
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING, FINDING, CONFIGURING, AWAITING_RELEASE ]
      when AWAITING_RELEASE
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING, FINDING, CONFIGURING, AWAITING_RELEASE ]
      when USER_RELEASED
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING, FINDING, CONFIGURING, AWAITING_RELEASE ]
      when DCC_RELEASED
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING, FINDING, CONFIGURING, AWAITING_RELEASE ]
      when RELEASED
        ok = [ PUBLISHING ]
      when RELEASE_REJECTED
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING, FINDING, CONFIGURING, AWAITING_RELEASE ]
      when FAILED
        ok = [ UPLOADING, DELETING ]
        ok.push VALIDATING if project.project_archives.find_all { |pa| pa.is_active }.size > 0
      end


      def ok.orjoin(delim = ", ", lastjoin = "or")
        if self.size > 2 then
          return "#{self[0...-1].join(delim)}#{delim}#{lastjoin} #{self[-1]}"
        elsif self.size > 1 then
          return self.join(" #{lastjoin} ")
        else
          return self.join(delim)
        end
      end

      return ok.uniq
    end

  end

end
