require 'open5_patches'

ActiveRecord::Base.send :include, Open5
ActionController::Base.send :include, Open5
