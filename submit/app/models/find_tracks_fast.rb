class FindTracksFast < FindTracks

  def controller
    @controller = FindFastTracksController.new(:command => self) unless @controller
    @controller
  end
end
