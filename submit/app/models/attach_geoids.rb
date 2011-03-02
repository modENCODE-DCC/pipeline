class AttachGeoids < Command

  module Status
    CREATING = "creating geoids to attach"
    CREATE_FAILED = "failed to create geoids"
    CREATED = "geoids created"
    ATTACHING = "attaching geoids to project"
    ATTACHED = "geoids attached"
    ATTACH_FAILED = "failed to attach geoids"
  end
  
  # attr_accessor :creating, :attaching # Why doesn't this work?

  def creating
    @creating
  end
  def attaching
    @attaching
  end
  def creating=(input)
    @creating = input
  end
  def attaching=(input)
    @attaching = input
  end
  
  def status=(newstatus)
    # Don't update project's status
    write_attribute :status, newstatus
  end

  def controller
    @controller = AttachGeoidsController.new(:command => self) unless @controller
    @controller
  end

end
