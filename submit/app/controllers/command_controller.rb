include Spawn
include Open5
class CommandController < ApplicationController
  def status
    self.command_object.status
  end

  def command_object
    return @command
  end

  def command_object=(obj)
    @command = obj
  end

  def initialize(options = {})
    if options[:command] then
      @command = options[:command]
      return
    end
    if self.class == CommandController then
      command_object = Command.new(options)
      command_object.save
    end
  end

  def timeout=(seconds)
    command_object.timeout = seconds
  end

  def timeout
    command_object.timeout
  end


  def queue(options = {})
    # This should queue and save this class
    command_object.status = Command::Status::QUEUED
    command_object.save

    unless (options[:defer] && options[:defer] == true) then
      CommandController.do_queued_commands
    end
  end
  def self.next_queued_command
    Command.find_all_by_status(Command::Status::QUEUED).sort { |a, b| a.queue_position <=> b.queue_position }.first
  end

  def self.do_queued_commands
    spawn do
      # Is a process already handling queued commands?
      # If so, return and let it do its thing
      if CommandController.running_flag then
        return
      end

      begin
        logger.info "Set semaphore true"
        CommandController.running_flag=true
      rescue ActiveRecord::StaleObjectError
        logger.error "Failed set semaphore"
        # Either exists and tried to create or lock_version was incremented 
        # by another process, and the copy we've got is stale
        return
      end
      begin
        # If we got this far, run any remaining queued commands
        while (next_command = CommandController.next_queued_command) do
          logger.info "Run #{next_command.class.name}"
          begin
            retval = next_command.controller.run

            if next_command.status == Command::Status::QUEUED || next_command.status == Command::Status::CANCELED then
              # Strange, we think we ran it but the status didn't get updated
              # Assume failure
              logger.error "Failure because command status is #{next_command.status} for #{next_command.id}"
              next_command.stderr = "Failure because command was supposed to run, but status is now #{next_command.status} instead"
              next_command.status = Command::Status::FAILED
              next_command.save
              raise CommandRunException.new("Command #{next_command.id} was run, but is still queued!")
            end

            if !retval then
              # If retval is false, run failed, and all queued commands in this project should be failed
              CommandController.disable_related_commands(next_command)
            end
          rescue CommandRunException
            # TODO: Failure handling
            logger.error "Command failed! #{$!}"
            CommandController.disable_related_commands(next_command)
          end
        end
      ensure
        logger.info "Resetting running flag #{$!}"
        CommandController.running_flag=false
      end
    end
  end

  def self.disable_related_commands(command)
    command.project.commands.find_all_by_status(Command::Status::QUEUED).each do |cmd|
      cmd.status = Command::Status::FAILED
      cmd.save
    end
    command.project.status = command.status
    command.project.save
  end
  def run
    # Quick 'n dirty distribution: command_object.command = "grid submit " + command_object.command
    command_object.start_time = Time.now
    command_object.save

    begin
      retval = yield if block_given?
    ensure
      command_object.end_time = Time.now
      command_object.save
    end
    # You can't do anything here! A return in the block_given will return right through run here
    # See http://innig.net/software/ruby/closures-in-ruby.rb, examples 12 and 13
  end

  def self.running_flag=(state)
    unless Semaphore.exists?(:flag => "running") then
      # If we can't create this object, then it probably means it was created between
      # the "unless" check above and the creation below. If that's the case, it's 
      # effectively a StaleObjectError and should be handled the same
      raise ActiveRecord::StaleObjectError unless Semaphore.new(:flag => "running").save
    end
    s = Semaphore.find_by_flag("running")
    s.value = state ? "true" : "false"
    s.save
  end
  def self.running_flag
    s = Semaphore.find_by_flag("running")
    if s && s.value == "true" then
      true
    else
      false
    end
  end
end
