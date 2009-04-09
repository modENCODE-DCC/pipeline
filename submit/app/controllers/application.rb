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
  def nil_flatten_compare(other)
    if other.is_a?(Enumerable) then
      if (self <=> other).nil?
        cmp_self = self.clone
        cmp_other = other.clone
        (0..self.size-1).each { |i|
          break unless i < other.size-1
          if cmp_self[i].nil? && cmp_other[i].nil? then
            cmp_self[i] = 0
            cmp_other[i] = 0
          elsif cmp_self[i].nil?
            cmp_self[i] = -1
            cmp_other[i] = 1
          elsif cmp_other[i].nil?
            cmp_self[i] = 1
            cmp_other[i] = -1
          end
          if (cmp_self[i] <=> cmp_other[i]).nil?
            cmp_self[i] = 0
            cmp_other[i] = 0
          end
        }
        return cmp_self <=> cmp_other
      end
      return self <=> other
    end
  end
end
class NilClass
  def compare(other)
    if (other == nil || other == false) then
      return 0
    else
      return -1
    end
  end
  def <=>(other)
    compare(other)
  end
end
