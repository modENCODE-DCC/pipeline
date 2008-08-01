# Open5, adapted from Open3
#
# Adds support for getting the return value of a program
# Adds support for reconnecting child process to ActiveRecord
module Open5
  def popen5(*cmd)
    pw = IO::pipe   # pipe[0] for read, pipe[1] for write
    pr = IO::pipe
    pe = IO::pipe
    sidechannel = IO::pipe
    exitvaluechannel = IO::pipe

    child = fork {
      # Don't need the ActiveRecord handle in here
      Spawn.close_resources
      ActiveRecord::Base::open5_reconnect
      grandchild = fork {
        Spawn.close_resources
        ActiveRecord::Base::open5_reconnect
	pw[1].close
	STDIN.reopen(pw[0])
	pw[0].close

	pr[0].close
	STDOUT.reopen(pr[1])
	pr[1].close

	pe[0].close
	STDERR.reopen(pe[1])
	pe[1].close

        exitvalue = -1
        begin
          exitvalue = exec(*cmd)
        rescue
          STDERR.puts "\nFailed to run command: #{$!}"
          exitvalue = -1
          sidechannel[1] << "Failed to run command: #{$!}"
          sidechannel[1].close
        ensure
          # to be safe, catch errors on closing the connnections too
          begin
            ActiveRecord::Base.connection.disconnect!
            ActiveRecord::Base.remove_connection
          rescue
          end
        end
        exit!(exitvalue)
      }


      Process.waitpid(grandchild)
      exitvalue = $?.exitstatus
      exitvaluechannel[1] << exitvalue
      exitvaluechannel[1].close
      exit!(0)
    }

    pw[0].close
    pr[1].close
    pe[1].close
    sidechannel[1].close
    exitvaluechannel[1].close

    Process.detach(child)

    # Write, Read, Error, exit value (int), SideChannel pipe (custom error output)
    pi = [pw[1], pr[0], pe[0], exitvaluechannel, sidechannel]
    pw[1].sync = true
    if defined? yield
      begin
	return yield(*pi)
      ensure
        pi.each{|p| if p.is_a?(IO) then; p.close unless p.closed?; end }
      end
    end
    pi
  end

  module_function :popen5
end

