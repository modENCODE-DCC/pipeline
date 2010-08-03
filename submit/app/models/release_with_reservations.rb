class ReleaseWithReservations < Release
  def initialize(options = {})
    super
    reservations = options[:reservations].nil? ? "No further details." : options[:reservations]
    self.reservations = reservations
  end

  def reservations
    if self.stderr =~ /Released with reservations: / then
      reservations = self.stderr.match(/Released with reservations: (.*)$/)[1]
      return reservations
    end
  end
  def reservations=(new_r)
    self.stderr = "" if self.stderr.nil?
    self.stderr = self.stderr.sub(/Released with reservations: .*$/, '')

    new_r = "Released with reservations: " + new_r
    if self.stderr.length > 0 then
      new_r = "\n" + new_r
    end
    self.stderr = self.stderr + new_r
  end
end
