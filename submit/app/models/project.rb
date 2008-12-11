class Project < ActiveRecord::Base

  belongs_to :user
  belongs_to :project_type
  belongs_to :group
  has_many :project_archives, :dependent => :destroy, :order => :archive_no
  has_many :commands, :dependent => :destroy, :order => :position
  has_many :track_tags, :dependent => :destroy
  has_many :track_stanzas, :dependent => :destroy

  validates_presence_of :name
  validates_presence_of :project_type_id
  validates_presence_of :status
  validates_presence_of :user_id
  validates_uniqueness_of   :name


  module Status
    include Command::Status
    include Upload::Status
    include Expand::Status
    include Validate::Status
    include Load::Status
    include Unload::Status
    include FindTracks::Status
    include Release::Status
    include Delete::Status
    # Status constants
    NEW = "new"
    CONFIGURING = "configuring tracks"
    CONFIGURED = "tracks configured"

    DELETED = "deleted" #i don't know if this is necessary
    FLAGGED = "flagged" #this could be useful for signaling between DCC and groups

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
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING, FINDING, CONFIGURING, AWAITING_RELEASE, USER_RELEASED, DCC_RELEASED ]
      when USER_RELEASED
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING, FINDING, CONFIGURING, AWAITING_RELEASE, DCC_RELEASED, RELEASED ]
      when DCC_RELEASED
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING, FINDING, CONFIGURING, AWAITING_RELEASE, USER_RELEASED, RELEASED ]
      when RELEASE_REJECTED
        ok = [ UPLOADING, DELETING, VALIDATING, LOADING, FINDING, CONFIGURING ]
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
