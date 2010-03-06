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
        if progress.to_i < 4096 then # 4K
          human_size = "#{progress} bytes"
        elsif progress.to_i < 4194304 # 4MB
          human_size = "#{progress.to_i/1048576} KB"
        elsif progress.to_i < 1073741824 # 1 GB
          human_size = "#{progress.to_i/1048576} MB"
        else
          human_size = "#{(progress.to_f/1073741824.to_f).round(1)} GB"
        end
        if content_length.to_i < 4096 then # 4K
          human_content_length = "#{content_length} bytes"
        elsif content_length.to_i < 4194304 # 4MB
          human_content_length = "#{content_length.to_i/1048576} KB"
        elsif content_length.to_i < 1073741824 # 1 GB
          human_content_length = "#{content_length.to_i/1048576} MB"
        else
          human_content_length = "#{(content_length.to_f/1073741824.to_f).round(1)} GB"
        end

        if progress_percent then
        "Uploading #{upurl}...<br/>\n#{progress_percent}% complete (#{human_size} of #{human_content_length} bytes transferred), #{self.status}."
        else
        "Uploading #{human_size}, #{self.status}."
        end
      else
        "Upload failed: #{self.stderr.gsub(/([\r\n])/, "<br/>\\1")}"
      end
    end
    
    def short_formatted_status
      unless self.status == Upload::Status::UPLOAD_FAILED then
        if progress.to_i < 4096 then # 4K
          human_size = "#{progress} bytes"
        elsif progress.to_i < 4194304 # 4MB
          human_size = "#{progress.to_i/1048576} KB"
        elsif progress.to_i < 1073741824 # 1 GB
          human_size = "#{progress.to_i/1048576} MB"
        else
          human_size = "#{(progress.to_f/1073741824.to_f).round(1)} GB"
        end
        if content_length.to_i < 4096 then # 4K
          human_content_length = "#{content_length} bytes"
        elsif content_length.to_i < 4194304 # 4MB
          human_content_length = "#{content_length.to_i/1048576} KB"
        elsif content_length.to_i < 1073741824 # 1 GB
          human_content_length = "#{content_length.to_i/1048576} MB"
        else
          human_content_length = "#{(content_length.to_f/1073741824.to_f).round(1)} GB"
        end
        (upurl, destfile) = self.command.split(/ to /).map { |i| URI.unescape(i) }
        if progress_percent then
          "Uploading #{upurl}.<br/>\n#{progress_percent}% complete. (#{human_size}/#{human_content_length}.)"
        else
          "Uploading #{upurl}.<br/>\n#{human_size}."
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
  class FileReplacement < Upload::File
    def controller
      @controller = ::FileUploadReplacementController.new(:command => self) unless @controller
      @controller = ::CommandController.new(:command => self) unless @controller
      @controller
    end
  end

  class UrlReplacement < Upload::Url
    def controller
      @controller = ::UrlUploadReplacementController.new(:command => self) unless @controller
      @controller = ::CommandController.new(:command => self) unless @controller
      @controller
    end
  end

  class Rsync < Upload::Url
   def controller
     @controller = ::RsyncUploadController.new(:command => self) unless @controller 
     @controller = ::CommandController.new(:command => self) unless @controller
     @controller
   end
   def formatted_status
   # Outputs the status of rsync; updates progress bar as new progress is passed
    (upuri, destfile) = self.command.split(/ to /).map { |i| URI.unescape(i) }
    output_string = "Uploading #{upuri} via rsync.<br/>" 
    if (self.stdout.nil?) or (self.stdout == "") then
      if (self.stderr.nil?) or (self.stderr == "") then
        return output_string
      end
      return output_string +  "<br/>Error! #{self.stderr.gsub!("\n","<br/>")}"
    end
    # Separate out the lines of output
    output = progress.split("\n") # Separate on newline
  
    # Note : the following block is mostly unnecessary--atm only the most recent
    # line of the progress bar is stored so we don't need to parse through to find
    # what's after the last carriage return. But it shouldn't be harmful.
    output.each{ |line|
      # If the last character is \r, remove it - it doesn't overwrite anything
      line.chomp!("\r")
      # Then, keep only text after the last \r - everything else's overwritten
      exclude = line.scan(/.*\r/) # Will have no more than one element
      line_start = 0
      exclude.each{|i| line_start = i.length - 1 } # Start after last \r
      line = line[line_start...line.length] # Remove info that's \r'd over 
      output_string += "#{line}<br/>"  # Add <br/> in place of \n
    }
    # Add any errors
    unless (self.stderr.nil?) or (self.stderr == "")  then
      output_string += "<br/>Error! #{self.stderr.gsub!("\n","<br/>")}"
    end
   output_string
   end
  end

  def fail
    self.status = Upload::Status::UPLOAD_FAILED
  end
end
