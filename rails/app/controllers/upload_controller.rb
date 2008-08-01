class UploadController < CommandController

  # UploadController methods
  protected 
  def do_before(options = {})
    command_object.project.status = Upload::Status::UPLOADING
    command_object.project.save

    if (options[:destfile]) then
      project_archive = command_object.project.project_archives.all.find { |pa| File.basename(pa.file_name) == File.basename(options[:destfile]) }
      if project_archive then
        project_archive.status = ProjectArchive::Status::UPLOADING
        project_archive.save
      end
    end
  end

  def do_after(options = {})
    # Update project status and clean up project archive
    project_archive = command_object.project.project_archives.all.find { |pa| File.basename(pa.file_name) == File.basename(options[:destfile]) }
    if command_object.status == Upload::Status::UPLOAD_FAILED then
      command_object.project.status = Upload::Status::UPLOAD_FAILED
      command_object.project.save
      project_archive.destroy if project_archive
      return false
    else
      command_object.project.status = Upload::Status::UPLOADED
      command_object.project.save
      if project_archive then
        project_archive.file_size = File.size(options[:destfile])
        project_archive.status = ProjectArchive::Status::NOT_EXPANDED
        project_archive.is_active = true
        project_archive.save
      end
    end
    return true
  end
end

