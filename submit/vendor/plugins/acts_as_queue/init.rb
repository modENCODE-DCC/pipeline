$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'active_record/acts/queue'
ActiveRecord::Base.class_eval { include ActiveRecord::Acts::Queue }
