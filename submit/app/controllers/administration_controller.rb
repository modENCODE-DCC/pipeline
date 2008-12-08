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

    @active_commands = Command.all.find_all { |c| Command::Status::is_active_state(c.status) }.sort { |c1, c2| c1.queue_position <=> c2.queue_position }
  end

  def admin_required
    access_denied unless current_user.is_a? Administrator
  end

  def list

    @autoRefresh = true 
    @projects = Project.find(:all)#, :order => 'name')
    @project_status = (Command::Status.constants+Load::Status.constants+Unload::Status.constants+Project::Status.constants+Validate::Status.constants+Upload::Status.constants).uniq.sort 
    #for view: <td><%= select "foo", "status", @project_status, {:prompt => 'Change status'}  %></td>
 
    if params[:sort] then
      session[:sort_list] = Hash.new unless session[:sort_list]
      params[:sort].each_pair { |column, direction| session[:sort_list][column] = [ direction, Time.now ] }
    end
    @new_sort_direction = Hash.new { |hash, column| hash[column] = 'forward' }
    if session[:sort_list] then
      sorts = session[:sort_list].sort_by { |column, sortby| sortby[1] }.reverse.map { |column, sortby| column }
      @projects = @projects.sort { |p1, p2|
        p1_attrs = sorts.map { |col| (session[:sort_list][col][0] == 'backward') ?  p2.attributes[col] : p1.attributes[col] } << p1.id
        p2_attrs = sorts.map { |col| (session[:sort_list][col][0] == 'backward') ?  p1.attributes[col] : p2.attributes[col] } << p2.id
        p1_attrs <=> p2_attrs
      }
      session[:sort_list].each_pair { |col, srtby| @new_sort_direction[col] = 'backward' if srtby[0] == 'forward' && sorts[0] == col }
    end

  end

def button(options = {})
  button_text = options[:name]

  image_source =
    case options[:type]
      when 'edit':          "edit-find-replace.png"
      when 'preview':       "document-print-preview.png"
      when 'delete':        "edit-delete.png"
      else "list-add.png"
    end

  if button_text then
     button = "<button type='button'>#{button_text}</button>"
  else
     button = "<img src='/images/icons/#{image_source}' />"
  end
  if options[:link]
  target = 'a'
#    target = '#{options[:link]}{:action}'
#    target = params[:target].blank? ? ">" : " target='#{options[:target]}'>"
    "<a href='#{options[:link][:action]}/#{options[:link][:id]}'" + target + button + "</a>"
  else
    button
  end


end



end
