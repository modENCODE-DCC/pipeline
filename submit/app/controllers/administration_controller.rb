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
    @all_paused_commands = Command.find_all_by_status(Command::Status::PAUSED).sort { |c1, c2| c1.queue_position <=> c2.queue_position }
    @all_waiting_commands = (@all_queued_commands + @all_paused_commands).sort { |c1, c2| c1.queue_position <=> c2.queue_position }

    @active_commands = Command.all.find_all { |c| Command::Status::is_active_state(c.status) }.sort { |c1, c2| c1.queue_position <=> c2.queue_position }
  end

  def batch_queue
    @projects = Project.all
    @selected_projects = Array.new
    @tasks = [
      ["", ""],
      ["validate", "VALIDATING"],
      ["load", "LOADING"],
      ["find tracks", "FINDING"]
    ]
    @next_status = params[:filter]
    if @next_status then
      next_state = @tasks.find { |t| t[1] == @next_status }
      @do_task = next_state[0].capitalize
      @projects.reject! { |p| !Project::Status::ok_next_states(p).include?(Project::Status::const_get(next_state[1])) }
    else
      @projects = Array.new
    end
    @projects.sort! { |a, b| a.id <=> b.id }
    if params[:commit] then
      @next_state = Project::Status::const_get(@tasks.find { |t| t[0] == params[:commit].downcase }[1])

      @selected_projects = params[:selected_projects]

      case @next_state
      when Project::Status::VALIDATING
        pc = PipelineController.new
        @selected_projects.each { |proj_id|
          p = Project.find(proj_id)
          next unless Project::Status::ok_next_states(p).include?(Project::Status::VALIDATING)
          pc.do_validate(p)
        }
      when Project::Status::LOADING
        pc = PipelineController.new
        @selected_projects.each { |proj_id|
          p = Project.find(proj_id)
          next unless Project::Status::ok_next_states(p).include?(Project::Status::LOADING)
          pc.do_load(p)
        }
      when Project::Status::FINDING
        pc = PipelineController.new
        @selected_projects.each { |proj_id|
          p = Project.find(proj_id)
          next unless Project::Status::ok_next_states(p).include?(Project::Status::FINDING)
          pc.do_find_tracks(p)
        }
      end
    end
  end

  def set_running_flag
    if params[:running_flag].to_s == true.to_s then
      CommandController.running_flag = true
    else
      CommandController.running_flag = false
      sleep 1 # Because otherwise do_queued_commands doesn't always work?
      CommandController.do_queued_commands
    end
    redirect_to :action => :index
  end

  def pause
    command = Command.find(params[:id])
    if command && command.status == Command::Status::QUEUED then
      command.controller.queue
    else
      flash[:warning] = "Couldn't find command #{params[:id]} to pause."
    end
    redirect_to :action => :index
  end

  def unpause
    command = Command.find(params[:id])
    if command && command.status == Command::Status::PAUSED then
      command.status = Command::Status::QUEUED
      command.save
    else
      flash[:warning] = "Couldn't find command #{params[:id]} to unpause."
    end
    redirect_to :action => :index
  end

  def requeue
    command = Command.find(params[:id])
    if command && (command.status == Command::Status::PAUSED || command.status == Command::Status::QUEUED)  then
      oldstatus = command.status
      command.status = Command::Status::PAUSED # Don't do anything silly while moving
      command.save

      all_queued_commands = Command.find_all_by_status(Command::Status::QUEUED).sort { |c1, c2| c1.queue_position <=> c2.queue_position }
      all_paused_commands = Command.find_all_by_status(Command::Status::PAUSED).sort { |c1, c2| c1.queue_position <=> c2.queue_position }
      all_waiting_commands = (all_queued_commands + all_paused_commands).sort { |c1, c2| c1.queue_position <=> c2.queue_position }

      highest_position = all_waiting_commands.map { |cmd| cmd.queue_position }.max

      command.move_to_bottom_in_queue

      command.controller.queue
    else
      flash[:warning] = "Couldn't find command #{params[:id]} to requeue."
    end
    redirect_to :action => :index
  end

  def destroy_from_queue
    command = Command.find(params[:id])
    if command && (command.status == Command::Status::PAUSED || command.status == Command::Status::QUEUED)  then
      command.destroy
    else
      flash[:warning] = "Couldn't find command #{params[:id]} to destroy."
    end
    redirect_to :action => :index
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
