class DccReleaseController < ReleaseController
  def initialize(options = {})
    self.command_object = ReleaseWithReservations.new(options) if options[:reservations]
    super
  end
  def run
    super do
      if command_object.status == Release::Status::AWAITING_RELEASE || command_object.status == Release::Status::RELEASE_REJECTED then
        command_object.status = Release::Status::DCC_RELEASED
        command_object.stdout = "Submission ##{command_object.project.id} (#{command_object.project.name}) approved by DCC."
      elsif command_object.status == Release::Status::USER_RELEASED then
        if !command_object.backdated_by_project.nil? then
          # Backdate this project to match the one in command_object.backdated_by_project
          old_project = command_object.backdated_by_project
          # Get the old release date and set this Release object to the same date
          command_object.updated_at = command_object.end_time = command_object.start_time = old_project.release_date
          command_object.save
          # Get the old creation date and create a dummy upload for this project
          project = command_object.project
          u = Upload.new(:project => project, :status => Upload::Status::UPLOADED)
          u.start_time = u.end_time = u.created_at = u.updated_at = old_project.embargo_start_date
          u.stdout = "Dummy upload so that embargo date is backdated to submission ##{old_project.id}"
          u.save
          project.created_at = old_project.created_at
          project.save
        end
        command_object.status = Release::Status::RELEASED
        command_object.stdout = "Submission ##{command_object.project.id} (#{command_object.project.name}) approved by DCC and released by user!"
      end
      command_object.save
    end
  end
end
