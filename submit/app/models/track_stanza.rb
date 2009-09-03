require 'base64'
class TrackStanza < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  validates_presence_of :user_id
  validates_presence_of :project_id
  validates_presence_of :marshaled_stanza

  def stanza
    s = self.marshaled_stanza
    if s[0..10] == "b64_header" then
      # Remove (new) header
      s = s[11..-1]
      return Base64.decode64(Marshal.restore(s))
    else
      return Marshal.restore(s)
    end
  end
  def stanza=(newstanza)
    self.marshaled_stanza = "b64_header" + Base64.encode64(Marshal.dump(newstanza))
  end
end
