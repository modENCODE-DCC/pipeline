# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'socket'
class ApplicationController < ActionController::Base

  include AuthenticatedSystem

  rescue_from ActionController::UnknownAction, :with => :action_not_found

  def action_not_found(e)
    url = request.nil? ? "" : request.url
    redirect_to :controller => "error", :action => "404", :tried_url => url
  end

end
class FalseClass
  def <=>(other)
    other == false ? 0 : -1
  end
end
class TrueClass
  def <=>(other)
    other == true ? 0 : 1
  end
end
