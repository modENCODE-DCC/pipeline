class DccRejectController < ReleaseController
  def run
    super do
      command_object.status = Release::Status::RELEASE_REJECTED
      command_object.stdout = "Submission ##{command_object.project.id} (#{command_object.project.name}) marked invalid by the DCC:"
      command_object.save
    end
  end
end
