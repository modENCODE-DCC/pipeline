require 'base64'
class TrackStanza < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  validates_presence_of :user_id
  validates_presence_of :project_id
  validates_presence_of :marshaled_stanza

  def stanza
    s = self.marshaled_stanza
    return Marshal.restore(Base64.decode64(s))
  end
  def stanza=(newstanza)
    self.marshaled_stanza = Base64.encode64(Marshal.dump(newstanza))
  end
end
