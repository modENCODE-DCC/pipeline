require 'open3'

class Command < ActiveRecord::Base
  belongs_to :project
  acts_as_list :scope => :project_id
  acts_as_queue # Just a clone of acts_as_list with new method names

  module Status
    # Status constants
    QUEUED = "queued"
    FAILED = "failed" # Generic failure case; not to be used by subclasses
    CANCELING = "canceling"
    CANCELED = "canceled"
    PAUSED = "paused"

    def self.is_active_state(state)
      active_states = [
        Delete::Status::DELETING,
        Load::Status::LOADING,
        Expand::Status::EXPANDING,
        Release::Status::AWAITING_RELEASE,
        Unload::Status::UNLOADING,
        Upload::Status::UPLOADING,
        Validate::Status::VALIDATING,
        FindTracks::Status::FINDING
      ]
      return active_states.include?(state)
    end

    def self.is_failed_state(state)
      failed_states = [
        Upload::Status::UPLOAD_FAILED,
        Delete::Status::DELETE_FAILED,
        Load::Status::LOAD_FAILED,
        Expand::Status::EXPAND_FAILED,
        Unload::Status::UNLOAD_FAILED,
        Validate::Status::VALIDATION_FAILED,
      ]
      return failed_states.include?(state)
    end
  end

  def initialize(options = {})
    super()

    self.set_options(options)

    self.status = Command::Status::QUEUED unless self.status
    #self.class_name = self.class.name

    throw :no_project_provided unless (self.project && self.project.is_a?(Project))
    @package_dir = options[:package_dir]
  end

  def status=(newstatus)
    write_attribute :status, newstatus
    unless self.project.nil? then
      self.project.status = newstatus
      self.project.save
    end
  end

  def package_dir
    return @package_dir
  end
  def package_dir=(dir)
    @package_dir = dir
  end

  # TODO: format log, parse log for success
  def formatted_status
    "<b>STDERR:</b><pre>" + (self.stderr.nil? ? '' : self.stderr)+ "</pre>\n<b>STDOUT</b>:<pre>" + (self.stdout.nil? ? '' : self.stdout) + "</pre>"
  end

  def short_formatted_status
    stderr_lines = Array.new
    unless self.stderr.blank? then
      self.stderr.split($/).reverse[0...2].each do |line|
        stderr_lines.unshift line[0...50] + (line.size > 50 ? "..." : "")
      end
    end
    stdout_lines = Array.new
    unless self.stdout.blank? then
      self.stdout.split($/).reverse[0...2].each do |line|
        stdout_lines.unshift line[0...50] + (line.size > 50 ? "..." : "")
      end
    end
    "<b>STDERR:</b><pre>#{stderr_lines.join("\n")}</pre>\n<b>STDOUT</b>:<pre>#{stdout_lines.join("\n")}</pre>"
  end


  def controller
    unless @controller then
      class_name_parts = self.class.name.split(/::/)
      while class_name_parts.length > 0
        class_name_str = class_name_parts.reverse.join
        class_name_parts.pop
        begin
          @controller = "::#{class_name_str}Controller".camelize.constantize.new(:command => self)
          break
        rescue
          @controller = CommandController.new(:command => self)
          @controller = nil
        end
      end
      @controller = CommandController.new(:command => self) unless @controller
    end
    @controller
  end

  def set_options(options)
    self.update_attributes(filter_options(options))
  end
  def filter_options(options)
    keepers = self.attributes.keys.map { |k| k.to_sym }
    keepers = keepers + [ :project ]
    options.reject { |k, v| keepers.index(k).nil? }
  end

  def name
    self.type
  end
end
