class AccountController < ApplicationController

  layout 'account'
 
  # If you want "remember me" functionality, add this before_filter to Application Controller
  before_filter :login_from_cookie
  before_filter :login_required, :only => [ :change_profile ]

  def index
    redirect_to(:action => 'signup') unless logged_in? || User.count > 0
  end

  def login
    @redir_to = params[:url]
    return unless request.post?
    if @redir_to != URI.parse(@redir_to).path then
      @redir_to = nil
    end
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      if @redir_to && @redir_to.length > 0 then
        redirect_to @redir_to
      else
        redirect_to(:controller => '/pipeline', :action => 'show_user')
      end
    else
      flash[:error] = "Unknown user or password."
    end
  end

  def change_profile

    if self.current_user.is_a?(Administrator) && params[:id] then
      @user = User.find(params[:id])
      unless @user
        flash[:error] = "Cannot find user with id '#{params[:id]}'"
        flash.discard
        redirect_to(:controller => 'administration', :action => 'index')
      end
    else
      @user = self.current_user
    end

    @user.host = request.host
    @user.port = request.port

    @pis = get_pis.sort.map { |k, v| [ k.sub(/(, \S)\S*$/, '\1.'), v.sort.map { |vv| [ vv.sub(/(, \S)\S*$/, '\1.'), "#{vv}"] } + [[ k.sub(/(, \S)\S*$/, '\1.'), "#{k}"]] ] }

    return unless request.post?
    params[:user].delete_if { |k,v| !(['email', 'name', 'lab', 'institution', 'commit'].include?(k.to_s)) }
    unless params[:commit] == "Cancel"
      email_addr = params[:user].delete(:email)
      @user.update_attributes(params[:user])
      unless email_addr.blank? || email_addr == @user.email then
        begin
          @user.change_email_address(email_addr)
        rescue
          flash[:error] = "Invalid email address." 
          @changed = false
          return
        end
      end
      @user.save!
      flash[:notice] = "Profile has been successfully changed."
      # If the email was changed, remind the user they need to confirm it
      flash[:notice] += "<br/>Please click the link in your confirmation email to finalize your email address change." unless @user.new_email.nil? 
      redirect_to :action => :change_profile
      return
    else
      redirect_to(:controller => :pipeline, :action => :show_user)
      return
    end
  rescue ActiveRecord::RecordInvalid
    return
  end

  def change_email
    @user = current_user

    if params[:commit] == "Save" then
      @user.preferences["batch"] = params["batch"]["value"]
      @user.preferences["no_email"] = params["no_email"]["value"]
      @user.preferences["all_notifications"] = params["all_notifications"]["value"]
    end

    @batch = @user.preferences("batch")
    if CommandNotifier.get_liasons.keys.map { |u| User.find_by_login(u) }.include?(@user) && @batch.nil? then
      @batch = @user.preferences["batch"] = "true"
      @batch = @user.preferences("batch")
    end
    @no_email = @user.preferences("no_email")
    @all_notifications = @user.preferences("all_notifications")
  end

  def signup
    @pis = get_pis.sort.map { |k, v| [ k.sub(/(, \S)\S*$/, '\1.'), v.sort.map { |vv| [ vv.sub(/(, \S)\S*$/, '\1.'), "#{vv}"] } + [[ k.sub(/(, \S)\S*$/, '\1.'), "#{k}"]] ] }
    @user = User.new(params[:user])
    @user.host = request.host
    @user.port = request.port
    unless request.post?
      flash.clear
      return
    end
    @user.save!
    #@user.update_ftp_password
    # the next few lines are equivalent to instant autologin,
    # so they have been commented out and the welcome render added.
    # user's shouldn't get in until activated through email
    #self.current_user = @user
    # redirect_to(:controller => '/account', :action => 'index')
    #flash[:notice] = "Thanks for signing up!"
    render :action => 'welcome'
  rescue ActiveRecord::RecordInvalid
    render :action => 'signup'
  end
  
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
     redirect_to(:controller => '/welcome', :action => 'index')
  end

  def activate
    flash.clear  
    return if params[:id] == nil and params[:activation_code] == nil
    activator = params[:id] || params[:activation_code]
    @user = User.find_by_activation_code(activator) 
    if @user
      @user.host = request.host
      @user.port = request.port
    end
    if @user and @user.activate
      flash[:notice] = 'Your account has been activated.  Please log in.'
       redirect_to(:controller => '/account', :action => 'login')
    else
      flash[:error] = 'Unable to activate the account.  Please check or enter manually.' 
       redirect_to(:controller => '/account', :action => 'login')
    end
  end


  # reset lost password section
  def forgot_password
    return unless request.post?
    if @user = User.find_by_email(params[:email])
      @user.host = request.host
      @user.port = request.port
      @user.forgot_password
      @user.save
      redirect_to(:controller => '/account', :action => 'index')
      flash[:notice] = "A password reset link has been sent to your email address." 
    else
      flash[:error] = "Could not find a user with that email address." 
    end
  end

  def reset_password
    @user = User.find_by_password_reset_code(params[:id]) if params[:id]
    raise if @user.nil?
    return if @user unless params[:user]
    if (params[:user][:password] == params[:user][:password_confirmation])
        @user.update_attributes(params[:user])
        @user.reset_password
        if @user.activated_at.nil? then
          @user.activated_at = Time.now.utc
        end
        @user.save
        flash[:notice] = @user.save ? "Password reset." : "Password not reset." 
      else
        flash[:error] = "Password mismatch." 
      end  
      redirect_to(:controller => '/account', :action => 'index') 
  rescue
    flash[:error] = "Sorry - that is an invalid password reset code. Please check your code and try again. Perhaps your email client inserted a carriage return." 
     redirect_to(:controller => '/account', :action => 'index')
  end


  # change password section
  def change_password
    return unless request.post?
    unless params[:commit] == "Cancel"
      @user = self.current_user
      @user.update_attributes(params[:user])
      @user.new_email = ""  # prevent it from thinking it's new email which triggers email notify
      # until we have a place to redirect back to, just log them out  
      @user.forget_me if logged_in?  # part of log out, it must be before reset_password flag is set
      @user.reset_password
      @user.save!  # put this after all other change to @user to prevent multiple email notices
      @user.update_ftp_password
      cookies.delete :auth_token
      reset_session
      flash[:notice] = "Password has been successfully changed."
      redirect_to(:action => 'index')
    else # cancel
      redirect_to(:controller => '/pipeline', :action => 'show_user')
    end
  rescue ActiveRecord::RecordInvalid
    render :action => 'change_password'
  end

  def activate_new_email
    flash.clear  
    return unless params[:id].nil? or params[:email_activation_code].nil?
    activator = params[:id] || params[:email_activation_code]
    @user = User.find_by_email_activation_code(activator) 
    if @user and @user.activate_new_email
      redirect_to(:controller => '/pipeline', :action => 'show_user')
      flash[:notice] = "The email address for your account has been updated." 
    else
      flash[:error] = "Unable to update the email address." 
    end
  end

  private
  def get_pis
    pis = Hash.new
    if File.exists? "#{RAILS_ROOT}/config/PIs.yml" then
      pis = [ open("#{RAILS_ROOT}/config/PIs.yml") { |f| YAML.load(f.read) } ]
      pis = pis.first unless pis.nil?
    end
    pis = Hash.new if pis.nil?
    return pis
  end

end
