class FindTracksFast < FindTracks

  def controller
    @controller = FindTracksFastController.new(:command => self) unless @controller
    @controller
  end
end
