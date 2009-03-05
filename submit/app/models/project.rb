class Project < ActiveRecord::Base

  belongs_to :user
  belongs_to :project_type
  belongs_to :group
  has_many :project_archives, :dependent => :destroy, :order => :archive_no
  has_many :commands, :dependent => :destroy, :order => :position
  has_many :track_tags, :dependent => :destroy
  has_many :track_stanzas, :dependent => :destroy
  has_many :comments, :dependent => :destroy, :order => :created_at

  validates_presence_of :name
  validates_presence_of :project_type_id
  validates_presence_of :status
  validates_presence_of :user_id
  validates_uniqueness_of   :name

  def released?
    self.status == Project::Status::RELEASED
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
        Delete::Status::DELETE_FAILED,
        Load::Status::LOAD_FAILED,
        Expand::Status::EXPAND_FAILED,
        Unload::Status::UNLOAD_FAILED,
        Validate::Status::VALIDATION_FAILED,
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
