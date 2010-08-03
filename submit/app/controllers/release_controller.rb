class ReleaseController < CommandController
  def initialize(options)
    super
    if block_given? then
      # Don't create an Unload object if a subclass gave us a block to use
      yield
      return if self.command_object
    end

    self.command_object = Release.new(options) unless self.command_object
  end

  def run
    super do
      # Just pass this block to the parent
      return yield
    end
  end


end
