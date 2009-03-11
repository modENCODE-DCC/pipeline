class ErrorController < ApplicationController
  def _404
    @tried_url = params[:tried_url]
    render :action => "404", :layout => false
  end

  def method_missing(method_id)
    if method_id =~ /^\d/ then
      method_id = "_#{method_id}"
      old_params = params.reject { |k, v|
        [:action, "action", :controller, "controller", :id, "id"].include?(k)
      }
      redirect_to ({ :action => method_id }.merge(old_params))
    else
      redirect_to :action => "404"
    end
  end
end
