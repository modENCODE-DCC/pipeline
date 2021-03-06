class UploadController < CommandController

  # UploadController methods
  protected 
  def do_before(options = {})
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
    if project_archive then
      if command_object.status == Upload::Status::UPLOAD_FAILED then
        #project_archive.destroy if project_archive
        return false
      else
        project_archive.file_size = File.size(options[:destfile])
        project_archive.status = ProjectArchive::Status::NOT_EXPANDED
        project_archive.is_active = true
        # Add signature
        mysignature = PipelineController.new.generate_file_signature(options[:destfile])
        project_archive.signature = mysignature
        project_archive.save
      end
    end
    return true
  end
end

