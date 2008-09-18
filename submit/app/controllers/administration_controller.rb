class AdministrationController < ApplicationController
  before_filter :login_required
  before_filter :admin_required

  def index
    @commands = Command.all
    project = Project.first || Project.new(:id => 0)
    project_dir = ExpandController.path_to_project_dir(project)
    if File.directory? project_dir then
      File.stat(project_dir) # Make sure any automounting that needs to be done is done
    end
    @files = [ project_dir ]

    @all_queued_commands = Command.find_all_by_status(Command::Status::QUEUED).sort { |c1, c2| c1.queue_position <=> c2.queue_position }

    @active_commands = Command.all.find_all { |c| c.status =~ /ing$/ }.sort { |c1, c2| c1.queue_position <=> c2.queue_position }
  end

  def admin_required
    access_denied unless current_user.is_a? Administrator
  end
end
