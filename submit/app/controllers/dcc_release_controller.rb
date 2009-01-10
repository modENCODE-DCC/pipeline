class DccReleaseController < ReleaseController
  def run
    super do
      if command_object.status == Release::Status::AWAITING_RELEASE || command_object.status == Release::Status::RELEASE_REJECTED then
        command_object.status = Release::Status::DCC_RELEASED
        command_object.stdout = "Submission ##{command_object.project.id} (#{command_object.project.name}) approved by DCC."
      elsif command_object.status == Release::Status::USER_RELEASED then
        command_object.status = Release::Status::RELEASED
        command_object.stdout = "Submission ##{command_object.project.id} (#{command_object.project.name}) approved by DCC and released by user!"
      end
      command_object.save
    end
  end
end
