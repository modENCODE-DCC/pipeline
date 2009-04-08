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
    (other == false || other == nil) ? 0 : -1
  end
end
class TrueClass
  def <=>(other)
    other == true ? 0 : 1
  end
end
class Array
  def orjoin(delim = ", ", lastjoin = "or")
    if self.size > 2 then
      return "#{self[0...-1].join(delim)}#{delim}#{lastjoin} #{self[-1]}"
    elsif self.size > 1 then
      return self.join(" #{lastjoin} ")
    else
      return self.join(delim)
    end
  end
  def andjoin(delim = ", ", lastjoin = "and")
    self.orjoin(delim, lastjoin)
  end
end
class NilClass
  def <=>(other)
    if (other == nil || other == false) then
      return 0
    else
      return -1
    end
  end
end
class Numeric
  old_comp = self.instance_method(:<=>)
  define_method(:<=>) do |other|
    default_result = old_comp.bind(self).call(other)
    (default_result.nil? && other == nil) ? 1 : default_result
  end
end
class Date
  old_comp = self.instance_method(:<=>)
  define_method(:<=>) do |other|
    default_result = old_comp.bind(self).call(other)
    (default_result.nil? && other == nil) ? 1 : default_result
  end
end
