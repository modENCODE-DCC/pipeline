require 'base64'
class TrackStanza < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  validates_presence_of :user_id
  validates_presence_of :project_id
  validates_presence_of :marshaled_stanza

  def stanza
    s = self.marshaled_stanza
    if s[0..9] == "b64_header" then
      # Remove (formerly new) header
      s = s[10..-1]
      return Marshal.restore(Base64.decode64(s))
    else
      return Marshal.restore(s)
    end
  end
  def stanza=(newstanza)
    self.marshaled_stanza = Marshal.dump(newstanza)
  end
end
