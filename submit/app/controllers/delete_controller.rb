require 'find'
class DeleteController < CommandController
  def initialize(options)
    super
    return unless options[:command].nil?

    self.command_object = Delete.new(options)
    command_object.command = "Project #{options[:project].id}"
    command_object.save
  end

  def run
    super do
      if block_given? then
        # Don't run this method, just pass it along to the super-super class
        return yield
      end
      command_object.status = Delete::Status::DELETING
      command_object.stdout = ""
      command_object.stderr = ""
      command_object.save

      project = command_object.project
      if project.nil? then
        command_object.stderr = "Project #{command_object.command} has already been deleted"
        command_object.status = Delete::Status::DELETE_FAILED
        command_object.save
        return false
      end

      # Delete everything but the files specifically referenced in a ProjectArchive
      # First, get rid of the extracted files
      project.project_archives.each do |project_archive|
        ExpandController.remove_extracted_folder(project_archive)
      end

      # Next, delete any remaining files that aren't the same as the ProjectArchive files
      project_dir = ExpandController.path_to_project_dir(project)
      project_archive_files = project.project_archives.map { |pa| File.join(project_dir, pa.file_name) }
      Find.find(project_dir) do |file|
        next if project_dir == file
        next if project_archive_files.find { |paf| paf == file }
        if File.directory? file then
          if File.basename(file) == "tracks" then
            FileUtils.remove_entry_secure(file)
          end
        else
          File.delete(file)
        end
      end

      # Dissasociate this command object from the project it's deleting so we have a record of it
      command_object.project = nil
      command_object.save

      # Destroy the project entry in the database
      project.destroy

      command_object.status = Delete::Status::DELETED
      command_object.save

      return true
    end
  end
end

