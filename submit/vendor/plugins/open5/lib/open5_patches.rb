# Adapted from the spawn plugin

class ActiveRecord::Base
  # reconnect without diconnecting
  def self.open5_reconnect(klass=self)
    spec = @@defined_connections[klass.name]
    konn = active_connections[klass.name]
    # remove from internal arrays before calling establish_connection so that
    # the connection isn't disconnected when it calls AR::Base.remove_connection
    @@defined_connections.delete_if { |key, value| value == spec }
    active_connections.delete_if { |key, value| value == konn }
    establish_connection(spec ? spec.config : nil)
  end
  def self.open5_disconnect(klass=self)
    spec = @@defined_connections[klass.name]
    konn = active_connections[klass.name]
    # remove from internal arrays before calling establish_connection so that
    # the connection isn't disconnected when it calls AR::Base.remove_connection
    @@defined_connections.delete_if { |key, value| value == spec }
    active_connections.delete_if { |key, value| value == konn }
  end
end

