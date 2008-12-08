require 'open-uri'
class Upload < Command
  module Status
    UPLOADING = "uploading"
    UPLOADED = "uploaded"
    UPLOAD_FAILED = "upload failed"
  end

  # File uploader (copy source to filename)
  class File < Upload
    def formatted_status
      (source, destfile) = self.command.split(/ to /).map { |i| URI.unescape(i) }
      basename = ::File.basename(destfile)
      case self.status
      when Upload::Status::UPLOADED
        "Finished uploading #{basename}."
      when Upload::Status::UPLOAD_FAILED
        "Failed to upload #{basename}: #{self.stderr}"
      else
        "Currently uploading #{basename}."
      end
    end
  end

  # URL uploader
  class Url < Upload::File
    # Reuse the stderr field for content_length
    def content_length=(length)
      self.stderr = length
    end
    def content_length
      self.stderr
    end

    # Reuse the stdout field for progress_length
    def progress=(prog)
      self.stdout = prog
    end
    def progress
      self.stdout
    end

    def formatted_status
      (upurl, destfile) = self.command.split(/ to /).map { |i| URI.unescape(i) }
      unless self.status == Upload::Status::UPLOAD_FAILED then
        if progress_percent then
        "Uploading #{upurl}...<br/>\n#{progress_percent}% complete (#{progress} of #{content_length} bytes transferred), #{self.status}."
        else
        "Uploading #{progress} bytes, #{self.status}."
        end
      else
        "Upload failed: #{self.stderr.gsub(/([\r\n])/, "<br/>\\1")}"
      end
    end
    
    def short_formatted_status
      unless self.status == Upload::Status::UPLOAD_FAILED then
        if progress_percent then
          (upurl, destfile) = self.command.split(/ to /).map { |i| URI.unescape(i) }
        "Uploading #{upurl}.<br/>\n#{progress_percent}% complete. (#{progress}/#{content_length} bytes.)"
        else
        "Uploading #{upurl}.<br/>\n#{progress } bytes."
        end
      else
        "Upload failed: #{self.stderr.gsub(/([\r\n])/, "<br/>\\1")}"
      end
    end

    def progress_percent
      if self.content_length && self.content_length.to_f > 0 && self.progress && self.progress.to_f >= 0 then
        ((self.progress.to_f / self.content_length.to_f) * 100).round
      end
    end
  end
end
