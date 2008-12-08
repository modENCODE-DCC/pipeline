class TrackStanza < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  validates_presence_of :user_id
  validates_presence_of :project_id
  validates_presence_of :marshaled_stanza

  def stanza
    return Marshal.restore(self.marshaled_stanza)
  end
  def stanza=(newstanza)
    self.marshaled_stanza = Marshal.dump(newstanza)
  end
end
