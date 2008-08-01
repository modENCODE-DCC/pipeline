class WelcomeController < ApplicationController

def index
  if logged_in? then
    redirect_to :controller => "pipeline", :action => "show_user"
  end
end

def contact
end

end
