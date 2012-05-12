require 'tempfile'

class GenomeBuilds

# this will parse the genome_builds.ini file from the validator
# and turn it into something the track finder can use.
# 
#
# it will make a GenomeBuilds object which you can query with a 
# chromosome name and it will return all possible organisms
# 
# or , you can just query it and it'll return all the organisms
# it knows about.
# it also knows the lengths of the organisms chroms.
# Run it in the rails context so it knows RAILS_ROOT

  # Usage: mygb = GenomeBuilds.new("script/validators/modencode/genome_builds.ini)
  # possible_array = mygb.guess_organism("chrX")
  # found_organism = mygb.organism 

  # This is the magical string used to determine which build is the most up to date
  # If it is not updated during liftovers there will obviously be problems.
  CURRENT_BUILD_STRING = {
    "melanogaster" => "FlyBase r5",
    "elegans" => "WormBase WS220",
    "sechellia" => "FlyBase-dsec r1.3",
    "persimilis" => "FlyBase-dper r1.3",
    "ananassae" => "FlyBase-dana r1.3",
    "mojavensis" => "FlyBase-dmoj r1.3",
    "pseudoobscura" => "FlyBase-dpse r2.6",
    "simulans" => "FlyBase-dsim r1.3",
    "virilis" => "FlyBase-dvir r1.2",
    "yakuba" => "FlyBase-dyak r1.3",
    "briggsae" => "WormBase-cbriggsae WS225",
    "remanei" => "WormBase-cremanei WS225",
    "brenneri" => "WormBase-cbrenneri WS227",
    "japonica" => "WormBase-cjaponica WS227"
  }


  def initialize( options = {})
    @source_file = options[:file] || "/var/www/submit/script/validators/modencode/genome_builds.ini"
    # if we're copying from a genome build
    @organisms = GenomeBuilds.deep_copy(options[:organisms]) || Hash.new
    @found_chroms_ok = false
    parse unless( options[:noparse] || options[:organisms])
  end

  def self.deep_copy(inp)
  # from http://stackoverflow.com/questions/5643432/whats-the-most-efficient-way-to-deep-copy-an-object-in-ruby
    if inp.is_a? Hash
      res = Hash.new
      inp.each{|k, v| res[k] = self.deep_copy(v)}
      res
    elsif inp.is_a? Array
      inp.map{|i| self.deep_copy(i)}
    else
      inp
    end
  end

  def clone
    GenomeBuilds.new(:file => @source_file, :organisms => @organisms, :noparse => true)
  end
  
  # deletes organisms if they don't have the appropriate chromosome
  def guess_by_chrom!(input_chrom, input_chrom_length = 0)
    # future TODO : if they include a length for the chromosome,
    # use it to narrow down the build even further
    # strip chr if necessary
    chr = input_chrom.sub(/^chr/, "")
    @organisms.delete_if{|build, org_hash|
      ! org_hash["chromosomes"].keys.include? chr
    }
    # Check if @organisms has changed
    new_organisms_hash = @organisms.hash
    if @organisms_hash != new_organisms_hash
      @found_chroms_ok = false
      @organisms_hash = new_organisms_hash
    end
  end

  # Try and eliminate organisms by name
  def guess_by_name!(inp)
    inp = [inp] unless inp.is_a? Array
    targets = inp.map{|i| make_shortname(i)}
    # so now we have an array of orgnames.
    # we want to reject all items from orglist that DONT match a least one of those names
    @organisms.delete_if{|k, v| ! (targets.include? v["shortname"]) }
    
    # Check if @organisms has changed
    new_organisms_hash = @organisms.hash
    if @organisms_hash != new_organisms_hash
      @found_chroms_ok = false
      @organisms_hash = new_organisms_hash
    end
  end

  # returns the build key name for the most current build to use
  def best_build
    raise CantDetermineOrganism, "Don't know what organism to use out of [#{self.possible_organisms.join(", ")}]!" unless self.organism?
    CURRENT_BUILD_STRING[self.organism]
  end

  # Given a tmpdir and an optional build, creates a bigwig chromfile
  # build should be in the format used by genome_builds.ini
  def generate_chromfile(tmpdir, options = {})
    build_to_use = options[:build] || self.best_build
    # Create a new tmpfile in the tmpdir
    chromfile = Tempfile.new(@organisms[build_to_use]["shortname"], tmpdir)
    #chromname \tab chromlength
    @organisms[build_to_use]["chromosomes"].each{|k, v|
      chromfile.puts "#{k}\t#{v}"
    }
    chromfile.close
    chromfile
  end
  

  # Do we have exactly one organism ? 
  def organism?
    self.possible_organisms.length == 1
  end
  #  have we found the single organism that we know this to be?
  # returns false if we haven't, and nil if we ran out.
  def organism
    # for now, return if we know what organism it is but not what build
    # (ie, same shortname.)
    # otherwise, false or nil depending on error condition.
    shortnames = self.possible_organisms
    return shortnames[0] if shortnames.length == 1
    return false if @organisms.keys.length > 1
    return nil if @organisms.keys.length == 0
    return "This should never happen!"
  end

  # a list of the organisms we have not yet ruled out
  def possible_organisms
    @organisms.keys.map{|k| @organisms[k]["shortname"]}.uniq
  end

  # Are there more than one possible organisms
  def eliminated?
    possible_organisms.length <= 1
  end

  def empty?
    @organisms.empty?
  end

  # Checks all existing organisms for the input chrom
  # and returns whether at least one of them has it
  # without eliminating anything. Used for things that
  # might not be chroms.
  def has_chromosome?(chrom)
    # calculate the known chromosomes if it's out of date
    # ie, inconsistent with the organisms we think it is
    unless @found_chroms_ok then
      @found_chroms = Array.new
      @organisms.each{|k, v| @found_chroms +=  v["chromosomes"].keys}
      @found_chroms_ok = true
    end
    @found_chroms.include? chrom
  end
  
  def organisms # future TODO delete this, for testing only
    @organisms
  end


  private
    def parse
      # reset the organism
      @organisms = Hash.new

      ini = File.open(@source_file, "r")
      
      while line = ini.gets do
        line.chomp!
        
        # skip blank lines
        next if line =~ /^\s*$/
        # if it's [genome_build , parse new organism
        # and add it to the organisms hash
        if line =~ /^\s*\[/ then
          curr_build = parse_organism(line) if line =~ /^\s*\[/
          @organisms[curr_build] = Hash.new
          next
        end
        # otherwise, it's a content line.
        (prop, value) = parse_property(line) 
        # set it up.
        case prop
          when "organism"
            @organisms[curr_build]["organism"] = value
            # and set up the 'shortname'
            @organisms[curr_build]["shortname"] = make_shortname(value)
          when "type"
            @organisms[curr_build]["type"] = value
          when "chromosomes"
            # set up the chromosomes hash
            @organisms[curr_build]["chromosomes"] = Hash.new
            # parse chromosomes into an array
            chroms = parse_chromosomes(value)
            chroms.each{|chr|
              @organisms[curr_build]["chromosomes"][chr] = nil
            }
          else # it's a chromosome line
            # parse it into chromname, length
            (chr, length) = parse_chromosome_line(prop, value)
            # add it if length is not nil (because there are start lines)
            @organisms[curr_build]["chromosomes"][chr] = length  unless length.nil?
        end
      end
      ini.close
      @organisms_hash = @organisms.hash
    end

   def make_shortname(orgname)
     # converts an organism name ("Drosophilia melanogaster" ) into just the second bit "melanogaster"
     # (or last if there are three, eg dpse)
     orgname.sub(/^.* /, "")
   end

    # format : [genome_build ORGANISM BUILD]
    def parse_organism(line)
      line.sub("[genome_build ", "").sub("]", "")
    end

    # format : organism=SOME STUFF
    def parse_property(line)
      line.split("=")
    end
  
    # format : 2, 2R, 3, 3L, 
    def parse_chromosomes(line)
      line.split(", ")
    end

    def parse_chromosome_line(prop, value)
      return [nil, nil] if prop =~ /_start$/
      [prop.sub("_end", ""), value]
    end
end

class CantDetermineOrganism < StandardError
end
