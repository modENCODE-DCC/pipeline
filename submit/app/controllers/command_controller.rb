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
#    spawn do
      # Is a process already handling queued commands?
      # If so, return and let it do its thing
      if CommandController.running_flag then
        return
      end

      begin
        logger.info "Set semaphore true"
        CommandController.running_flag=true
      rescue ActiveRecord::StaleObjectError
        logger.info "Failed set semaphore"
        # Either exists and tried to create or lock_version was incremented 
        # by another process, and the copy we've got is stale
        return
      end
      begin
        # If we got this far, run any remaining queued commands
        while (next_command = CommandController.next_queued_command) do
          logger.info "Run #{next_command.class.name}"
          begin
            if !next_command.controller.run then
              CommandController.disable_related_commands(next_command)
            end
          rescue CommandRunException
            # TODO: Failure handling
            logger.info "Command failed! #{$!}"
            CommandController.disable_related_commands(next_command)
          end
        end
      ensure
        logger.info "Resetting running flag #{$!}"
        CommandController.running_flag=false
      end
  end

  def self.disable_related_commands(command)
    command.project.status = command.status
    command.project.save
    command.project.commands.find_all_by_status(Command::Status::QUEUED).each do |cmd|
      cmd.status = Command::Status::FAILED
      cmd.save
    end
  end
  def run
    # Quick 'n dirty distribution: command_object.command = "grid submit " + command_object.command
    retval = yield if block_given?
    # If retval is false, run failed, and all queued commands in this project should be failed
    if command_object.status == Command::Status::QUEUED || command_object.status == Command::Status::CANCELED then
      # Strange, we think we ran it but the status didn't get updated
      # Assume failure
      logger.info "Failure because command status is #{command_object.status}"
      command_object.status = Command::Status::FAILED
      command_object.save
      raise CommandRunException.new("Command #{command_object.id} was run, but is still queued!")
    end
    return retval if block_given?
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
