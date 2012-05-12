require 'genome_builds'

# WiggleToBedgraph
# For converting wiggle files to bedgraph format, as a preliminary to
# converting them to bigWig.
#
# Usage: converter = WiggleToBedgraph.new( "/tmp", self, :cmd_puts) 
#  This will send output to the cmd_puts method of the calling class
#
# [organism, output_bedgraph_path] = converter.convert(source_path, basename) 
# Basename is the name we'll refer to the wiggle file with
# 
# Available Methods
# split_by_track(source_file)
#   -> [ { :handle => handle, :desc => desc, :name => name}, ... ]
#     
#
#
#


class MissingOrganismError < StandardError
end
class WiggleOutOfOrderError < StandardError
end
class WiggleIOError < StandardError
end

class WiggleToBedgraph
  
  GENOME_BUILD_FILE = "/var/www/submit/script/validators/modencode/genome_builds.ini"


  def initialize(tmpdir, output_class = nil, output_method = nil)
    @tmpdir = tmpdir
    @output_class = output_class
    @output_method = output_method
    @organism_name = nil
  end

  # If we already know what the organism is, set it up here
  def set_organism(shortname)
    cmd_puts "Setting organism to #{shortname} for WiggleToBedgraph" if debugging?
    @organism_name = shortname
  end

  # This will send output to the appropriate place
  def cmd_puts(message)
    if @output_class && @output_method then
      @output_class.send(@output_method, message)
    else
      puts message
    end
  end

  def debugging?
    @debugging
  end
  def debugging=(inp)
    @debugging = inp
  end

  # 

 # Helper methods: converting wiggle to bed as a preface for converting to bigWig

  # Determine if a wiggle file contains multiple tracks and split it into one file per track if it does
  # Returns an array of hashes. 
  # Hashes contain :handle -> closed file handle to wiggle file, :name -> string, :desc -> string
  def split_by_track(sourcepath)
    current_track = false
    result_tracks = []
    has_tracks = false
    trackname = trackdesc = nil
    # Attempt to open the file
    begin     
      ifstream = File.open(sourcepath, "r")
    rescue Exception => e
      cmd_puts "      Error opening source wiggle file  at location #{sourcepath}:\n       #{e}."
      return []
    end       
    # read the file until we encounter a non-{comment/whitespace/empty} line
    ifstream.each{|line|
      next if line =~/^\s*#|^\s*$|^$/ ;
      if ( line =~ /^\s*track/ ) then
        cmd_puts "got trackline:[#{line}]" if debugging?
        # Assumption: if there are any track lines in the file,
        # there will be a track line before any data lines.
        cmd_puts "          Detected track line in #{File.basename sourcepath} at line #{ifstream.lineno}" +
          "#{has_tracks ? "." : "; splitting file into multiple tracks." }" 
        has_tracks = true
        
        # If we have a track going, finish it off, & make a new track tmpfile.
        if current_track then 
          current_track.close 
          result_tracks << {:handle => current_track, :name => trackname, :desc => trackdesc}
        end
        
        # Get new track info:
        # Match is (whitespace delimited) or (surrounded by quotes), and then beginning & ending quotes are removed.
        trackname = line.match(/name=("([^"]*)"|\S*)/)
        trackdesc = line.match(/description=("([^"]*)"|\S*)/)
        trackname = trackname[1] unless trackname.nil?
        trackdesc = trackdesc[1] unless trackdesc.nil?
        trackname.gsub!(/(^"|"$)/, "") unless trackname.nil?
        trackdesc.gsub!(/(^"|"$)/, "") unless trackdesc.nil?

        current_track = Tempfile.new((trackname.nil? ? "wiggle_track" : trackname.gsub(/\s/, "_")), @tmpdir)
        current_track.puts line
      elsif has_tracks then
        # We're accumulating data lines
        current_track.puts line
      else    
        cmd_puts "we believe #{File.basename sourcepath} to be only a single track" if debugging? 
        # we got a data line with no track line: we assume there is one track.
        ifstream.close
        result_tracks << {:handle => ifstream, :name => trackname, :desc => trackdesc}
        break
      end     
    }           
    # Close and list the last tempfile
    if current_track then
      current_track.close
      result_tracks << {:handle => current_track, :name => trackname, :desc => trackdesc }
    end
    cmd_puts "Track list:[#{result_tracks.inspect}]" if debugging?
    return result_tracks 
  end




  # Complains if the features are not in numerical order
  def validate_wiggle_line_order(prevstart, start, linenum, fname)
    if prevstart >= start then
      raise WiggleOutOfOrderError, "Line #{linenum} of #{fname}: data lines out of order! " +
                                   "This line start: #{start}; previous line start: #{prevstart}"
    end
    true
  end


  def wiggle_print_delayed_line(line_hash, next_start, ofstream, linenum, warncount)
    max_num_warnings = 100
    toreturn = 0
    return toreturn unless line_hash # if it's false / nil, don't need to do anything
    # If there's an overlap, return 1 for the warning count and move the end coordinate
    if next_start && (next_start < line_hash[:end1] ) then
      toreturn = 1
      # And warn in the log unless we've reached the limit
      case warncount <=> max_num_warnings
        when -1
          cmd_puts "        WARNING: Found overlapping features at lines #{linenum - 1} and #{linenum}:\n" + 
                   "         Pushing back earlier feature's end coordinate (originally #{line_hash[:end1]}) to #{next_start}!"
        when 0
          cmd_puts "\n      ***\n      Overlap warning limit of #{max_num_warnings} reached--further overlaps will be corrected silently.\n      ***"
      end
      line_hash[:end1] = next_start
    end
    # Print the line
    ofstream.puts "#{line_hash[:chrom]} #{line_hash[:start0]} #{line_hash[:end1]} #{line_hash[:score]}"
    return toreturn
  end


  #  converts files for converting to bigwig & determines organism.
  # Input : path to input wiggle file, original name for debugging purposes
  # Output : [GenomeBuilds organism, string bedgraph_path] 
  # NOTE: All of these wiggles are expected to have passed through the validator. They're either coming from
  # embedded in the chadoxml or, if sufficiently large, a "cleaned wiggle file" in the directory itself.
  # FORMATTING NOTE:
  # fixedStep and variableStep wiggles are 1-based: the first base of an N-base chromosome is 1 and the last is N.
  # Span, when present, indicates the number of bases a feature covers.
  # bedGraph is 0-based half-open (ie, the end coordinate is "the first base no longer covered by this feature")
  # so, a fixedStep with start of 11 and span of 5 (so last base is 15) translates to bedGraph as [10 15).
  def convert(sourcepath, basename)
    
    organism = GenomeBuilds.new(GENOME_BUILD_FILE) # the organism we've determined this to have
    organism.guess_by_name!( @organism_name ) unless @organism_name.nil?
    params = Hash.new # The wiggle parameters for this section of the file
    delayed_line_to_print = false # Whether there is an unprinted line that needs to be finished --
    # used in variableStep and bedGraph which may have erroneous overlapping lines.
    
    ofstream = nil # stream to current output bed 

    # Try to open the file
   begin
      ifstream = File.open(sourcepath, "r")
    rescue Exception => e
      raise WiggleIOError "Couldn't open #{basename} at #{sourcepath}:\n#{e}."
      return
    end
   
    # Make the output file
    begin
        ofstream = Tempfile.new(basename, @tmpdir)
      # Testing 
      #ofstream = File.open("/users/ekephart/tmp/#{basename}.temp", "w" )
    rescue Exception => e
      raise WiggleIOError, "Couldn't create temp file in #{@tmpdir}: #{e}."
      return
    end

    format =  chrom = start = step = span = nil # Information about the lines that needs to be retained between loops.
    warncount = 0 # How many overlaps have we warned for? To prevent spamming the output too much.
    
    prev_start0 = -1 # Start of the previous line--for ensuring that lines are in numerical order
    prev_chrom = "" # Used for tracking chrom changes for numerical order validation in bedGraphs.
    
    linenum = 0 # declaration for scoping

    # Read the file and convert it
    ifstream.each{|line|
      line.chomp!
      linenum = ifstream.lineno
      # Skip comments, blank lines, track definitions.
      next if line =~ /^#|^\s$|^$/
      if line =~ /^track/ then
        # Clear the delayed line and reset numerical order but otherwise skip... for now
        warncount += wiggle_print_delayed_line(delayed_line_to_print, nil, ofstream, linenum, warncount)
        delayed_line_to_print = false
        prev_start0 = -1
        next # SKIP IT!
       end
  
      # Get info from header lines
      if line=~ /chrom/ then
        # Finish processing possible previous line and clear it
        warncount += wiggle_print_delayed_line(delayed_line_to_print, nil, ofstream, linenum, warncount)
        delayed_line_to_print = false
        prev_start0 = -1 # Also reset order

        format  = (regmatch = /^(variableStep|fixedStep)/.match line ; regmatch.nil? ? nil : regmatch[1] )
        chrom     = (regmatch = /chrom=(\S+)/.match line ; regmatch.nil? ? nil : regmatch[1] )
        start     = (regmatch = /start=(\d+)/.match line ; regmatch.nil? ? nil : regmatch[1].to_i )
        step      = (regmatch = /step=(\d+)/.match line ; regmatch.nil? ? nil : regmatch[1].to_i )
        span      = (regmatch = /span=(\d+)/.match line ; regmatch.nil? ? 1 : regmatch[1].to_i ) # Default span is 1

        # Complain of missing fields
        if chrom.nil? || (format == "fixedStep" && step.nil? ) then
          cmd_puts "      ERROR: Declaration line \"#{line}\" at #{basename}:#{linenum} is missing fields or invalid! Cannot continue!"
          ofstream.close
          return [false, nil]
        end
        organism.guess_by_chrom!(chrom) unless organism.organism?
        if organism.empty? then
          ofstream.close
          raise MissingOrganismError, "Couldn't find any organism with chromosome name #{chrom}!"
          return
        end
        
        # trim span to step if necessary
        if step && span > step then
            cmd_puts "      WARNING: wiggle file #{basename} has span #{span} > step #{step} starting at line #{linenum}.  Reducing span to step & continuing."
            span = step
        end
        # Remove 'chr' from chrom if presnt
        chrom.sub!("chr", "")  
      else 
        # Process data line. nil format implies bedGraph. See formatting notes in method header for coordinate substitution info.
        case format
          when "fixedStep" # 1-based
            start0 = start - 1
            end1 = start0 + span
            score = line.to_f
            ofstream.puts "#{chrom} #{start0} #{end1} #{score}"
            start += step # Update params for next line
          when "variableStep" # 1-based
            # Delay printing the line until we confirm the start location of the next line.
            contents = line.split
            start0 = contents[0].to_i - 1
            score = contents[1].to_f
            return  unless validate_wiggle_line_order(prev_start0, start0, linenum, basename) # will raise
            # Finish processing the previous delayed line if it exists
            warncount += wiggle_print_delayed_line(delayed_line_to_print, start0, ofstream, linenum, warncount)
            # Then, set up printing of this line.
              delayed_line_to_print = { :chrom => chrom,
                                        :score => score,
                                        :start0 => start0,
                                        :end1 => start0 + span,
                                        :needs_printing => true}
            prev_start0 = start0
          when nil
            # Assume it's a bedGraph. Delay printing until next start location is confirmed.
            # Check for organism
            contents = line.split
            chrom = contents[0]
            start0 = contents[1].to_i
            end1 = contents[2].to_i
            # If we got a new chrom, reset lines-numerical-order
            if chrom != prev_chrom then
              prev_start0 = -1
              prev_chrom = chrom
            end
            return unless validate_wiggle_line_order(prev_start0, start0, linenum, basename) # will raise
            organism.guess_by_chrom!(chrom) unless organism.eliminated?
            if organism.empty? then
              ofstream.close
              raise MissingOrganismError, "Couldn't find any organism with chromosome name #{chrom}!"
            end
            # Print previous line if necessary
            # If previous line was on a different chromosome than this one, don't worry about clipping the end!
            start0_or_nil = (  prev_start0 == -1 ? nil : start0 )
            warncount += wiggle_print_delayed_line(delayed_line_to_print, start0_or_nil, ofstream, linenum, warncount)
            # And set up current line for printing in a bit
            delayed_line_to_print = { :chrom => chrom,
                                      :score => contents[3],
                                      :start0 => start0,
                                      :end1 => end1,
                                      :needs_printing => true }
            prev_start0 = start0
          else # This should never happen
            cmd_puts "Error: format \"#{format}\" is neither fixedStep, variableStep, or blank! This seems impossible!"
        end
      end
    }

    warncount += wiggle_print_delayed_line(delayed_line_to_print, nil, ofstream, linenum, warncount)

    ofstream.close unless ofstream.nil?

    # Complain if we never determined organism
    unless organism.organism? then
      raise MissingOrganismError, "Can't determine organism of #{basename} between #{organism.possible_organisms.join(", ")}!"
    end

    [organism, ofstream.path]
  end

end
