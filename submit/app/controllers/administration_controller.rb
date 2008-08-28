class AdministrationController < ApplicationController
  before_filter :login_required
  before_filter :admin_required

  def index
    @commands = Command.all
    project = Project.first || Project.new(:id => 0)
    project_dir = ExpandController.path_to_project_dir(project)
    File.stat(project_dir) # Make sure any automounting that needs to be done is done
    @files = [ project_dir ]
  end

  def admin_required
    access_denied unless current_user.is_a? Administrator
  end
end
