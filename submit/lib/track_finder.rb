require 'rubygems'
require 'dbi'
require 'pg'
require 'sqlite3'
require 'applied_protocol'
require 'cgi'
require 'find'
require 'pp'
#require 'pg_database_patch'

class Citation < ActionView::Base
  def initialize(project_id)
    @project_id = project_id
  end
  def build
    b = binding
    citation_text = ""
    f = File.new("../app/views/pipeline/citation.rhtml")
    erb = ERB.new(f.read, nil, nil, "citation_text")
    erb.filename = File.expand_path(f.path)
    erb.result(b)
  end
end

class TrackFinder

  # Configuration constants
  GD_COLORS = ['red', 'green', 'blue', 'white', 'black', 'orange', 'lightgrey', 'grey']

  # Track finding constants
  @debugging = false
  TRACKS_PER_COLUMN = 5
  MAX_FEATURES_PER_CHR = 10000
  CHROMOSOMES = {
              :dmelanogaster => [ '2L', '2LHet', '2R', '2RHet', '3L', '3LHet', '3R', '3RHet', '4', 'X', 'XHet', 'YHet', 'U', 'Uextra', 'M' ],
              :celegans => ['I', 'II', 'III', 'IV', 'V', 'X', 'MtDNA' ]
  }
  # Path to chromosome files for bigwig conversion
  CHROMFILE_DMEL_R5 = File.join(RAILS_ROOT, "config", "FlyBase_r5.chrom")
  CHROMFILE_CELEGANS_190 = File.join(RAILS_ROOT, "config", "WormBase_WS190.chrom") # OLD
  CHROMFILE_CELEGANS_220 = File.join(RAILS_ROOT, "config", "WormBase_WS220.chrom")

  # GBrowse configuration
  def self.gbrowse_root
    if File.exists? "#{RAILS_ROOT}/config/gbrowse.yml" then
      gbrowse_config = open("#{RAILS_ROOT}/config/gbrowse.yml") { |f| YAML.load(f.read) }
      return gbrowse_config['root_dir'];
    else
      raise Exception.new("You need a gbrowse.yml file in your config/ directory with at least a root_dir in it.")
    end
  end
  def self.gbrowse_lib
    return File.join(gbrowse_root, 'lib')
  end
  def self.gbrowse_database
    if File.exists? "#{RAILS_ROOT}/config/gbrowse_database.yml" then
      db_definition = open("#{RAILS_ROOT}/config/gbrowse_database.yml") { |f| YAML.load(f.read) }
      dbinfo = Hash.new
      dbinfo[:adaptor] = db_definition['adaptor']
      dbinfo[:perl_dsn] = db_definition['perl_dsn']
      dbinfo[:ruby_dsn] = db_definition['ruby_dsn']
      dbinfo[:user] = db_definition['user']
      dbinfo[:password] = db_definition['password']
      return dbinfo
    else
      raise Exception.new("You need an gbrowse_database.yml file in your config/ directory with at least an adaptor and dsn.")
    end
  end
  def self.gbrowse_tmp
    if File.exists? "#{RAILS_ROOT}/config/gbrowse.yml" then
      gbrowse_config = open("#{RAILS_ROOT}/config/gbrowse.yml") { |f| YAML.load(f.read) }
      return gbrowse_config['tmp_dir'];
    else
      raise Exception.new("You need a gbrowse.yml file in your config/ directory with at least a tmp_dir in it.")
    end
  end

  # Perl helper scripts
  GFF_TO_WIGDB_PERL = <<-EOP
  use strict;
  use lib '#{TrackFinder.gbrowse_lib}';
  use Bio::Graphics::Wiggle;

  my $wig_db_file = <>;
  my $chr = <>;
  my $range = <>;
  chomp $wig_db_file; chomp $chr; chomp $range;

  my ($min, $max) = split / /, $range;

  my $wigfile = new Bio::Graphics::Wiggle(
    $wig_db_file,
    1, # writeable
    {
      seqid => $chr,
      min => int($min),
      max => int($max),
      step => 1,
      span => 1,
    }
  );
  my ($startmin, $endmax);
  my $accum = 0;
  while (<>) {
    my ($start, $end, $value) = split / /;
    $startmin = $start if (($start < $startmin) || (!defined($startmin)));
    $endmax = $end if (($end > $endmax) || (!defined($endmax)));
    $wigfile->set_range($start => $end, $value);
    $accum += ($end-$start);
  }
  my $length = $endmax-$startmin;
  my $mean = ($accum*$max) / $length;
  my $stdev = sqrt( (($max-$mean)**2 + ($mean)**2)/$length );

  $wigfile->mean($mean);
  $wigfile->stdev($stdev);
  
  EOP
  WIGGLE_TO_BIGWIG_PERL = <<-EOP
  use strict;
  use lib '/modencode/raw/tools//Bio-BigFile-1.04/lib';
  use Bio::DB::BigFile;

  open STDERR, '>&STDOUT'; # Redirect STDERR to STDOUT
  my $wiggle_source_file = <>;
  my $chrom_file = <>;
  my $bigwig_output_file = <>; 
  chomp $bigwig_output_file; chomp $chrom_file; chomp $wiggle_source_file;

  Bio::DB::BigFile->createBigWig($wiggle_source_file, $chrom_file, $bigwig_output_file); 
  
  EOP
  LOAD_GFF_TO_GFFDB_PERL = <<-EOP
  use strict;
  use lib '#{TrackFinder.gbrowse_lib}';
  use File::Spec;
  use Bio::DB::SeqFeature::Store::GFF3Loader;
  use Bio::DB::SeqFeature::Store;

  my $gff_file = <>;
  my $adaptor = <>;
  my $dsn = <>;
  my $user = <>;
  my $pass = <>;
  my $schema = <>;
  chomp $gff_file; chomp $adaptor; chomp $dsn; chomp $user; chomp $pass; chomp $schema;

  my $tmpdir = File::Spec->tmpdir();

  my $store = Bio::DB::SeqFeature::Store->new(
    -dsn => $dsn,
    -adaptor => $adaptor,
    -user => $user,
    -pass => $pass,
    -tmpdir => $tmpdir,
    -write => 1,
    -create => 0,
    -schema => $schema
  ) or die "Couldn't connect to the GFF database";

  my $loader = Bio::DB::SeqFeature::Store::GFF3Loader->new(
    -store => $store,
    -sf_class => "Bio::DB::SeqFeature",
    -verbose => 1,
    -tmpdir => $tmpdir,
    -fast => 1
  ) or die "Couldn't create GFF3 loader";

  # on signals, give objects a chance to call their DESTROY methods
  $SIG{TERM} = $SIG{INT} = sub { undef $loader; undef $store; die "Aborted..."; };

  $loader->load($gff_file);

  EOP
  LOAD_SCHEMA_TO_GFFDB_PERL = <<-EOP
  use strict;
  use DBI;

  my $dsn = <>;
  my $user = <>;
  my $pass = <>;
  chomp $dsn; chomp $user; chomp $pass;

  my $dbh = DBI->connect($dsn, $user, $pass);

  my $ddl = "";
  while (<>) {
    $ddl .= $_;
  }

  $dbh->do($ddl);
  $dbh->disconnect();

  EOP

  # Chado database methods
  def database
    if File.exists? "#{RAILS_ROOT}/config/idf2chadoxml_database.yml" then
      db_definition = open("#{RAILS_ROOT}/config/idf2chadoxml_database.yml") { |f| YAML.load(f.read) }
      dbinfo = Hash.new
      dbinfo[:dsn] = db_definition['ruby_dsn']
      dbinfo[:user] = db_definition['user']
      dbinfo[:password] = db_definition['password']
      return dbinfo
    else
      raise Exception.new("You need an idf2chadoxml_database.yml file in your config/ directory with at least a Ruby DBI dsn.")
    end
  end
  def search_path=(search_path)
      dbh_safe { @dbh.do "SET search_path = #{search_path}, wiggle, pg_catalog" }
  end
  def get_experiments
    schemas = dbh_safe {
      sth_schemas = @dbh.prepare "SELECT DISTINCT schemaname FROM pg_views WHERE schemaname LIKE 'modencode_experiment_%' AND schemaname NOT LIKE 'modencode_experiment_%_data'"
      schemas = Hash.new
      sth_schemas.execute
      sth_schemas.fetch do |row|
        schemas[row[0]] = nil
      end
      sth_schemas.finish

      schemas.keys.each do |schema|
        sth_experiments = @dbh.prepare "SELECT DISTINCT experiment_id, uniquename FROM #{schema}.experiment"
        sth_experiments.execute
        schemas[schema] = sth_experiments.fetch
        sth_experiments.finish
      end
      schemas.reject { |sch, exp| exp.nil? }
    }
  end
  def there_are_feature_relationships?
    dbh_safe {
      sth_get_num_feature_relationships = @dbh.prepare("SELECT COUNT(fr.feature_relationship_id) FROM feature_relationship fr INNER JOIN data_feature df ON fr.object_id = df.feature_id")
      sth_get_num_feature_relationships.execute
      ret = (sth_get_num_feature_relationships.fetch[0] > 0) ? true : false
      sth_get_num_feature_relationships.finish
      return ret
    }
  end
  def dbh_safe
    if block_given? then
      begin
        return yield
      rescue DBI::DatabaseError => e
        cmd_puts "DBI error: #{e.err} #{e.errstr}"
        if defined? logger then
          logger.error e
        else
          $stderr.puts e
        end
        @dbh.disconnect unless @dbh.nil?
        return false
      end
    end
  end

  # Utility methods
  def initialize(command_object = nil)
    dbinfo = self.database
    @command_object = command_object
    @dbh = DBI.connect(dbinfo[:dsn], dbinfo[:user], dbinfo[:password])
    require 'pg_database_patch'

    # Track finding queries:
    @sth_get_experiment_id = dbh_safe { 
      @dbh.prepare("SELECT experiment_id FROM experiment")
    }
    @sth_get_data_by_applied_protocols = dbh_safe {
      @dbh.prepare("SELECT 
                   d.data_id,
                   d.heading, 
                   d.name, 
                   d.value, 
                   c.name AS type,
                   COUNT(df.*) AS number_of_features, 
                   COUNT(wig.*) AS number_of_wiggles
                   FROM data d 
                   INNER JOIN applied_protocol_data apd ON d.data_id = apd.data_id 
                   INNER JOIN cvterm c ON d.type_id = c.cvterm_id
                   LEFT JOIN data_feature df ON df.data_id = d.data_id
                   LEFT JOIN data_wiggle_data wig ON wig.data_id = d.data_id
                   WHERE apd.applied_protocol_id = ANY(?)
                   GROUP BY d.data_id, d.heading, d.name, d.value, c.name
                   HAVING 
                     count(wig.*) > 0 OR 
                     COUNT(df.*) > 0 OR 
                     (c.name = 'Sequence_Alignment/Map (SAM)' OR c.name = 'Binary Sequence_Alignment/Map (BAM)')") 
    }
    @sth_get_features_by_data_ids = dbh_safe {
      @dbh.prepare("SELECT
                   d.heading || ' [' || CASE WHEN d.name IS NULL THEN '' ELSE d.name END || ']' AS data_name,
                   f.feature_id,
                   f.name, f.uniquename,
                   cvt.name AS type,
                   o.genus, o.species
                   FROM data_feature df
                   INNER JOIN feature f ON f.feature_id = df.feature_id
                   INNER JOIN organism o ON f.organism_id = o.organism_id
                   INNER JOIN cvterm cvt ON f.type_id = cvt.cvterm_id
                   INNER JOIN data d ON df.data_id = d.data_id
                   INNER JOIN generate_series(1, ?) idx(n) ON (CAST(? AS int[]))[idx.n] = df.data_id
                   ORDER BY f.feature_id")
    }
    @sth_get_data_value_by_data_id = dbh_safe {
      @dbh.prepare("SELECT value FROM data WHERE data_id = ?")
    }
    @sth_get_featureprops_by_feature_id = dbh_safe {
      @dbh.prepare("SELECT 
                   fp.value AS propvalue, fp.rank AS proprank, fptype.name AS propname
                   FROM featureprop fp
                   INNER JOIN cvterm fptype ON fp.type_id = fptype.cvterm_id
                   WHERE fp.feature_id = ?")
    }
    @sth_get_featurelocs_by_feature_id = dbh_safe {
      @dbh.prepare("SELECT 
                   fl.fmin, fl.fmax, fl.strand, fl.phase, fl.rank, fl.residue_info,
                   src.name AS srcfeature,
                   src.uniquename AS srcfeature_accession,
                   src.feature_id AS srcfeature_id,
                   srctype.name AS srctype
                   FROM featureloc fl
                   LEFT JOIN (feature src
                     INNER JOIN cvterm srctype ON src.type_id = srctype.cvterm_id
                   ) ON src.feature_id = fl.srcfeature_id
                   WHERE fl.feature_id = ? ORDER BY fl.rank")
    }
    @sth_get_analysisfeatures_by_feature_id = dbh_safe {
      @dbh.prepare("SELECT 
                   af.rawscore AS score, af.normscore AS normscore, af.significance AS significance, af.identity AS identity,
                   a.program AS analysis
                   FROM analysisfeature af
                     INNER JOIN analysis a ON af.analysis_id = a.analysis_id
                   WHERE af.feature_id = ? LIMIT 1")
    }

    @sth_get_parts_of_features = dbh_safe {
      @dbh.prepare("SELECT
                   fr.object_id AS parent_id,
                   f.feature_id,
                   f.name, f.uniquename,
                   cvt.name AS type,
                   frtype.name AS relationship_type
                   FROM feature f
                   INNER JOIN cvterm cvt ON f.type_id = cvt.cvterm_id
                   INNER JOIN feature_relationship fr ON fr.subject_id = f.feature_id
                   INNER JOIN cvterm frtype ON fr.type_id = frtype.cvterm_id
                   INNER JOIN generate_series(1, ?) idx(n) ON (CAST(? AS int[]))[idx.n] = fr.object_id
                   ORDER BY feature_id DESC")
    }
    @sth_get_wiggles_by_data_ids = dbh_safe {
      @dbh.prepare("SELECT 
                   d.heading || ' [' || CASE WHEN d.name IS NULL THEN '' ELSE d.name END || ']' AS data_name,
                   d.value AS data_value,
                   wiggle_data.name, 
                   wiggle_data.wiggle_data_id,
                   wiggle_data.data AS wiggle_file,
                   cleaned_wig.value AS cleaned_wiggle_file,
                   cv.name AS cvname,
                   cvt.name AS term
                   FROM wiggle_data
                   INNER JOIN data_wiggle_data dwd ON wiggle_data.wiggle_data_id = dwd.wiggle_data_id 
                   INNER JOIN data d ON dwd.data_id = d.data_id
                   LEFT JOIN ( 
                     cvterm cvt INNER JOIN cv ON cvt.cv_id = cv.cv_id
                   ) ON cvt.cvterm_id = d.type_id
                   LEFT JOIN (
                     data_attribute da
                     INNER JOIN attribute cleaned_wig ON da.attribute_id = cleaned_wig.attribute_id AND cleaned_wig.heading = 'Cleaned WIG File'
                   ) ON d.data_id = da.data_id
                   WHERE dwd.data_id = ANY(?)") 
    }
    @sth_get_sam_by_data_ids = dbh_safe {
      @dbh.prepare("SELECT
                   d.heading || ' [' || CASE WHEN d.name IS NULL THEN '' ELSE d.name END || ']' AS data_name,
                   d.value AS sam_file,
                   attr_sorted_bam.value AS sorted_bam_file
                   FROM data d
                   INNER JOIN data_attribute da ON d.data_id = da.data_id 
                   INNER JOIN attribute attr_sorted_bam ON da.attribute_id = attr_sorted_bam.attribute_id
                   WHERE attr_sorted_bam.heading = 'Sorted BAM File' AND d.data_id = ANY(?)")
    }

    @sth_metadata = dbh_safe {
      @dbh.prepare "SELECT
      cur_output_data.value AS data_value,
      cur_output_data_type.name AS data_type,
      db.description AS db_type,
      db.url AS db_url,
      prev_apd.applied_protocol_id AS prev_applied_protocol_id,
      attr.value AS attr_value, attr_type.name AS attr_type, attr.heading AS attr_name

      FROM applied_protocol cur
      LEFT JOIN (applied_protocol_data cur_apd 
        INNER JOIN (data cur_output_data
          LEFT JOIN cvterm cur_output_data_type ON cur_output_data.type_id = cur_output_data_type.cvterm_id
          LEFT JOIN (dbxref dbx
            INNER JOIN db ON dbx.db_id = db.db_id
          ) ON dbx.dbxref_id = cur_output_data.dbxref_id
          LEFT JOIN (data_attribute da
            INNER JOIN attribute attr ON da.attribute_id = attr.attribute_id
            INNER JOIN cvterm attr_type ON attr_type.cvterm_id = attr.type_id
          ) ON da.data_id = cur_output_data.data_id
        ) ON cur_apd.data_id = cur_output_data.data_id
        LEFT JOIN applied_protocol_data prev_apd ON cur_apd.data_id = prev_apd.data_id AND prev_apd.direction = 'output'
      ) ON cur_apd.applied_protocol_id = cur.applied_protocol_id AND cur_apd.direction = 'input'


      WHERE cur.applied_protocol_id = ANY(?)"
    }
    @sth_leaf_metadata = dbh_safe {
      @dbh.prepare "SELECT
      cur_output_data.value AS data_value,
      cur_output_data_type.name AS data_type,
      db.description AS db_type,
      db.url AS db_url,
      prev_apd.applied_protocol_id AS prev_applied_protocol_id,
      attr.value AS attr_value, attr_type.name AS attr_type, attr.heading AS attr_name

      FROM applied_protocol cur

      LEFT JOIN (applied_protocol_data cur_apd 
        INNER JOIN (data cur_output_data
          LEFT JOIN cvterm cur_output_data_type ON cur_output_data.type_id = cur_output_data_type.cvterm_id
          LEFT JOIN (dbxref dbx
            INNER JOIN db ON dbx.db_id = db.db_id
          ) ON dbx.dbxref_id = cur_output_data.dbxref_id
          LEFT JOIN (data_attribute da
            INNER JOIN attribute attr ON da.attribute_id = attr.attribute_id
            INNER JOIN cvterm attr_type ON attr_type.cvterm_id = attr.type_id
          ) ON da.data_id = cur_output_data.data_id
        ) ON cur_apd.data_id = cur_output_data.data_id
        LEFT JOIN applied_protocol_data prev_apd ON cur_apd.data_id = prev_apd.data_id AND prev_apd.direction = 'input'
      ) ON cur_apd.applied_protocol_id = cur.applied_protocol_id AND cur_apd.direction = 'output'

      WHERE prev_apd.data_id IS NULL AND cur.applied_protocol_id = ANY(?)"
    }

    @sth_metadata_last = dbh_safe {
      @dbh.prepare "SELECT
      cur_output_data.value AS data_value,
      cur_output_data_type.name AS data_type,
      db.description AS db_type,
      db.url AS db_url,
      attr.value AS attr_value, attr_type.name AS attr_type, attr.heading AS attr_name

      FROM applied_protocol cur
      INNER JOIN generate_series(1, ?) idx(n) ON (CAST(? AS int[]))[idx.n] = cur.applied_protocol_id
      LEFT JOIN (applied_protocol_data cur_apd
        INNER JOIN (data cur_output_data
          LEFT JOIN cvterm cur_output_data_type ON cur_output_data.type_id = cur_output_data_type.cvterm_id
          LEFT JOIN (dbxref dbx
            INNER JOIN db ON dbx.db_id = db.db_id
          ) ON dbx.dbxref_id = cur_output_data.dbxref_id
          LEFT JOIN (data_attribute da
            INNER JOIN attribute attr ON da.attribute_id = attr.attribute_id
            INNER JOIN cvterm attr_type ON attr_type.cvterm_id = attr.type_id
          ) ON da.data_id = cur_output_data.data_id
        ) ON cur_apd.data_id = cur_output_data.data_id
      ) ON cur_apd.applied_protocol_id = cur.applied_protocol_id AND cur_apd.direction = 'output'"
    }
  end
  def cmd_puts(message)
    puts message + "\n" if debugging?
    return if @command_object.nil?
    @command_object.stdout = @command_object.stdout + message + "\n";
    @command_object.save
  end
  def debugging?
    return @debugging
  end
  def debugging=(enable_debug)
    @debugging = enable_debug
  end
  def delete_tracks(project_id, directory)
    cmd_puts "Removing old tracks and metadata."
    cmd_puts "  Removing tracks."
    Find.find(directory) do |path|
      Find.prune if File.directory?(path) && path != directory # Don't recurse
      if File.basename(path) =~ /^\d+[_\.]/ then
        File.unlink(path)
      end
    end
    cmd_puts "  Removing metadata."
    TrackTag.delete_all "project_id = #{project_id}"
    TrackStanza.delete_all "project_id = #{project_id}"
    cmd_puts "Done."
  end
  def get_next_tracknum
    unless Semaphore.exists?(:flag => "tracknum") then
      # If we can't create this object, then it probably means it was created between
      # the "unless" check above and the creation below. If that's the case, it's 
      # effectively a StaleObjectError and should be handled the same
      raise ActiveRecord::StaleObjectError unless Semaphore.new(:flag => "tracknum", :value => 0).save
    end
    s = Semaphore.find_by_flag("tracknum")
    s.value = s.value.to_i + 1
    s.save
    return s.value
  end

  # Helper methods: converting wiggle to bed as a preface for converting to bigWig

  # Given a track declaration line, parses it, making a hash of the result.
  def parse_wiggle_params_line(line)
    wiggle_params = { :format => false }

    # If there's no span, it won't need to be reformatted
    # However, still parse out the chrom for determining the organism
    if !( line =~ /span/i) then
      wiggle_params[:format] = "noSpan"
      wiggle_params[:chrom] = /chrom=\S+/.match(line).to_s[6..-1].sub("chr", "")
    # Otherwise, it must be either fixed or variableStep
    elsif line =~ /^fixedStep/ then
      wiggle_params[:format] = "fixedStep"
      wiggle_params[:chrom] = /chrom=\S+/.match(line).to_s[6..-1].sub("chr", "")
      wiggle_params[:start] = /start=\d+/.match(line).to_s[6..-1].to_i
      wiggle_params[:step] = /step=\S+/.match(line).to_s[5..-1].to_i
      wiggle_params[:span] = /span=\d+/.match(line).to_s[5..-1].to_i
    elsif line =~ /^variableStep/ then
      wiggle_params[:format] = "variableStep"
      wiggle_params[:chrom] = /chrom=\S+/.match(line).to_s[6..-1].sub("chr", "")
      wiggle_params[:span] = /span=\d+/.match(line).to_s[5..-1].to_i
    else
      # It has a span, but it's neither fixed nor variableStep
      wiggle_params[:format] = "unknown"
    end
    wiggle_params
  end

  # Takes: a variable_step line as a hash of
  #   :chrom, :score, :start0, :end0, :needs_printing
  #   where :start0, :end0 are 0 based half-open
  #   and the following line's 0-based start coordinate
  # Returns: the string of that line in .bed format.
  def finish_varstep_line(line, next_start=nil)
    # If the next line starts before this would finish, move this one's end up.
    line[:end0] = next_start if next_start && ( next_start < line[:end0] )
    "#{line[:chrom]}\t#{line[:start0]}\t#{line[:end0]}\t#{line[:score]}"
  end

  # Takes an array of possible organisms and a chrom string
  # Returns the array of organisms who have chrom as a chromosome
  # If there is but one, returns it in organism
  def eliminate_organisms(possible_organisms, chrom)
    possible_organisms = possible_organisms.select{|org| # Don't use select! - returns nil if no changes made
      CHROMOSOMES[org].include? chrom
    }
    organism = possible_organisms.length == 1 ? possible_organisms[0] : false
    cmd_puts "Unrecognized chromosome #{chrom}--unable to determine organism!" if possible_organisms.empty?
    [possible_organisms, organism] 
  end

  # Given an organism, return the path to the chromosome file to use
  def organism_to_chromfile(wig_organism)
    case wig_organism
      when :dmelanogaster
        CHROMFILE_DMEL_R5
      when :celegans
        CHROMFILE_CELEGANS_220
      else
        cmd_puts "    Error: cannot find chromosome file for organism \"#{wig_organism}\"!"
        false
    end
  end

  # Runs the bigwig writer
  # wig_path = source , bigwig_path = dest, chrom_path = chromosome file
  # Returns true if the bigwig file is created successfully ; false otherwise.
  def convert_to_bigwig(wig_path, chrom_path, bigwig_path)
    # TODO: Write the wiggle file locally, then move it to tracks dir
    # Do the bigwig conversion
    wiggle_writer = IO.popen("perl", "w+")
    wiggle_writer.puts WIGGLE_TO_BIGWIG_PERL + "\n\004\n"
    wiggle_writer.puts wig_path # Input
    wiggle_writer.puts chrom_path
    wiggle_writer.puts bigwig_path # Output
    cmd_puts wiggle_writer.readlines.map { |l| "      " + l.sub(/^\s*/, '') }.join("\n")
    wiggle_writer.close
    # Return false if the bigwig file wasn't created.
    File.exist?(bigwig_path)
  end


  # Takes: a read-filehandle source & write-filehandle output
  # converts a wiggle (fixed or variable step) file into bed format
  # Sourcename is for converting tmp wiggle files where the path may not be helpful in debugging
  # Returns an array [failed, original_ok, organism]
  # Failed -- the bed conversion failed but source is not necessarily appropriate to cvt to bigwig
  # Original_ok -- if true, no conversion done because original acceptable to cvt to bigwig
  # Organism -- organism determined based on correlation with the CHROMOSOMES hash
  def convert_wiggle_to_bed(source, output, sourcename)
    failed = false # did the wiggle fail to process?
    found_span = false # Have we seen a section with span yet?
    effective_span = false # We will use the step value if span > step in a fixedStep file
    original_ok = false # Can we just use the original wig
    params = {} # The parameters (1-based)
    # params are :format, :chrom, :start (for fixedStep), :step (for fixedStep), :span
    to_print = { :needs_printing => false }

    possible_organisms = CHROMOSOMES.keys # We wish to narrow down the organisms that it could be. 
    organism = false
    determining_organism = false # Whether to figure out the organism & then quit
    
    source.each{|line|
      # Skip track definitions, comments, and blank lines
      next if line =~ /^#|^track|^\s*$/
      
      # If all we are doing is finding the organism
      if determining_organism then
        # Find the chrom more quickly - and bed-able.
        if params[:format]== "bed_file" then
          # If this is a chrom we've not encountered yet, check it
          curr_chrom = /^\S+\s/.match(line).to_s.strip
          unless params[:chrom] == curr_chrom then
            possible_organisms, organism = eliminate_organisms(possible_organisms, curr_chrom) 
            params[:chrom] = curr_chrom
          end
        end
        if line =~ /chrom/ then
          params = parse_wiggle_params_line(line)
          possible_organisms, organism = eliminate_organisms(possible_organisms, params[:chrom])
        end
        
        break if organism # We've found it

        if possible_organisms.empty? then
          failed = true # No idea what the organism is--abort
          break
        end
        next
      end

      # This part wants refactoring imo--see /gbrowse/lib/Bio/Graphics/Wiggle/Loader.pm for
      # a possible way to go about it
      # If there's a new declaration line, get new params 
      if line =~ /chrom/ then
        # First check to see if there's a previous line to finish off
        if to_print[:needs_printing] then
          output.puts finish_varstep_line(to_print)
          to_print[:needs_printing] = false
        end
        params = parse_wiggle_params_line(line)

        # Retain organisms which still match the chromosomes
        possible_organisms, organism = eliminate_organisms(possible_organisms, params[:chrom]) unless organism

        # reset the effective span (used in fixedStep if step > span)
        effective_span = false

        # Process inconsistent span
        if found_span && ( params[:format] == "noSpan" || params[:span] != found_span ) then
          cmd_puts "      Wigfile #{sourcename} at #{source.path} has an inconsistent span declaration--span must be the same for all sections."
          failed = true
          break
        end
        # If there's no span on the first pass, don't worry about inconsistency & use the file as is
        if params[:format] == "noSpan" then
          failed = false
          original_ok = true
          determining_organism = true
          break if organism # Escape if we already know the organism
        else 
          unless params[:format] =~ /Step/ then
            # Wasn't fixedStep or variableStep - we don't recognize the format!
            cmd_puts "      Error: Wigfile #{sourcename} at #{source.path} has a span,"
            cmd_puts "      but format #{params[:format]} is unrecognized--should be fixedStep or variableStep!"
            failed = true
            break
          end
        end
        found_span = params[:span] # If we got this far, a span exists in the file
        next
      end
      
      # Process a data line
      case params[:format]
        when "fixedStep"
          # fixedStep -- line is just score.
          # Convert from 1 based to 0-based half-open
          
          # Set the span -- if it's more than step, complain & set to step anyhow.
          effective_span = params[:span] unless effective_span
          if effective_span > params[:step] then
            cmd_puts "      Wigfile #{sourcename} has a span greater than the step--reducing it to step & proceeding anyway."
            effective_span = params[:step]
          end
         
          start0 = params[:start] - 1
          end0 = start0 + params[:span]
          score = line.to_f
          
          output.puts "#{params[:chrom]}\t#{start0}\t#{end0}\t#{score}"
          # and update the params for when we get the next line
          params[:start] += params[:step]
        when "variableStep"
          contents = line.split # this is 1-based
          start0 = contents[0].to_i - 1
          
          # First, if there's a previous line to process, do that now
          if to_print[:needs_printing] then
            output.puts finish_varstep_line(to_print, start0)
            to_print[:needs_printing] = false
          end
          # Then continue with the current line
          score = contents[1].to_f
          # Set up the line to be printed once the end coordinate is confirmed
          to_print = {:chrom => params[:chrom], 
                      :score => score, 
                      :start0 => start0, 
                      :end0 => start0 + params[:span],
                      :needs_printing => true}
        when nil
          # Didn't see a formatting line -- it might be a bed!
          if line =~ /^\S+\s+\d+\s+\d+\s+-?[\dEe.]+/ then
            # It matches bed's /chr start end score/ formatting
            params[:format] = "bed_file"
            original_ok = true
            determining_organism = true 
          else
            cmd_puts "      Error: can't determine format for wigfile #{sourcename} at #{source.path} from line:"
            cmd_puts "        #{line}"
            failed = true
            break
          end
        else
          cmd_puts "      Error: wigfile #{sourcename} at #{source.path} has unrecognized format #{params[:format]}!"
          failed = true
          break
      end
    }

    # Then print one last line if necessary
    if to_print[:needs_printing] then
      output.puts finish_varstep_line(to_print)
      to_print[:needs_printing] = false
    end
    
    # If it failed, we don't have an appropriate output 
    return failed, original_ok, organism
  end 

  # Track finding and output
  def find_usable_tracks(experiment_id, project_id)
    # Find the datum objects that have attached features (via data_feature) 
    # or wiggle data (via data_wiggle_data)

    usable_tracks = Hash.new { |hash, column| hash[column] = Array.new }
    cmd_puts "    Scanning protocols for inputs or outputs that could make tracks."
    applied_protocols = Hash.new { |hash, ap_id| hash[ap_id] = AppliedProtocol.new(:applied_protocol_id => ap_id) }

    # Get all the applied protocols for this experiment
    # Start with the first set of applied protocols
    dbh_safe { 
      sth_aps = @dbh.prepare("SELECT 
                             eap.first_applied_protocol_id,
                             apd.data_id AS input_data_id,
                             p.name AS protocol_name, p.protocol_id as protocol_id
                             FROM experiment_applied_protocol eap 
                             INNER JOIN applied_protocol ap ON eap.first_applied_protocol_id = ap.applied_protocol_id
                             INNER JOIN protocol p ON ap.protocol_id = p.protocol_id
                             LEFT JOIN applied_protocol_data apd ON eap.first_applied_protocol_id = apd.applied_protocol_id
                             WHERE experiment_id = ?")
      sth_aps.execute(experiment_id)
      sth_aps.fetch do |row|
        applied_protocols[row[0]].column = 0 # Note that the AP gets autocreated by the hash init block
        applied_protocols[row[0]].inputs.push(row[1]) if row[1]
        applied_protocols[row[0]].add_protocol({ :name => row[2], :id => row[3] })
      end
      sth_aps.finish
    }

    $stderr.puts "Got #{applied_protocols.size} applied protocols, I think" if @debug

    # Then follow the applied_protocol->datum->applied_protocol link
    column = 0
    seen_aps = Array.new
    dbh_safe {
      sth_aps = @dbh.prepare("SELECT 
                             apd_next.applied_protocol_id AS next_applied_protocol,
                             apd_next_all.data_id AS input_data_id,
                             p.name AS protocol_name, p.protocol_id as protocol_id
                             FROM applied_protocol_data apd_prev
                             INNER JOIN applied_protocol_data apd_next ON apd_next.data_id = apd_prev.data_id
                             INNER JOIN applied_protocol_data apd_next_all ON apd_next.applied_protocol_id = apd_next_all.applied_protocol_id
                             INNER JOIN applied_protocol ap_next ON ap_next.applied_protocol_id = apd_next.applied_protocol_id
                             INNER JOIN protocol p ON ap_next.protocol_id = p.protocol_id
                             WHERE
                             apd_prev.direction = 'output' AND apd_next.direction = 'input' AND apd_next_all.direction = 'input'
                             AND apd_prev.applied_protocol_id = ?")

      until applied_protocols.values.find_all { |ap| ap.column == column }.size == 0 do

        $stderr.puts "There are #{applied_protocols.values.find_all { |ap| ap.column == column }.size} aps for column #{column}" if @debug
        applied_protocols.values.find_all { |ap| ap.column == column }.map { |ap| ap.applied_protocol_id }.uniq.each do |applied_protocol_id|
          if seen_aps.include?(applied_protocol_id) then
            cmd_puts "ERROR: Looping back to previously seen protocols. Quitting!"
            cmd_puts "Please check your SDRF to make sure you don't have a value that's both an input and an output to the same protocol."
            return nil
          end
          sth_aps.execute(applied_protocol_id)
          seen_aps.push(applied_protocol_id)
          sth_aps.fetch do |row|
            applied_protocols[row[0]].column = column + 1 # Note that the AP gets autocreated by the hash init block
            applied_protocols[row[0]].inputs.push row[1]
            applied_protocols[row[0]].add_protocol({ :name => row[2], :id => row[3] })
          end
        end
        column = column + 1
      end
      sth_aps.finish

      column -= 1
      last_ap_ids = applied_protocols.find_all { |ap_id, ap| ap.column == column }.map { |ap_id, ap| ap_id }

      sth_last_aps = @dbh.prepare("SELECT 
                             apd.applied_protocol_id AS applied_protocol_id,
                             apd.data_id AS output_data_id,
                             p.name AS protocol_name, p.protocol_id as protocol_id
                             FROM applied_protocol_data apd
                             INNER JOIN applied_protocol ap ON apd.applied_protocol_id = ap.applied_protocol_id
                             INNER JOIN protocol p ON ap.protocol_id = p.protocol_id
                             WHERE
                             apd.direction = 'output' AND ap.applied_protocol_id = ?")
      last_ap_ids.each { |applied_protocol_id|
        sth_last_aps.execute(applied_protocol_id)
        sth_last_aps.fetch do |row|
          applied_protocols[row[0]].outputs.push row[1]
        end
      }

      sth_last_aps.finish
      column += 1
    }

    cmd_puts "    Done."

    # Currently, each set of inputs or outputs for an applied protocol is a potential track
    # tracks = applied_protocols.values.map { |ap| ap.inputs } + applied_protocols.values.map { |ap| ap.outputs }

    cmd_puts "    Collapsing applied protocols to reduce duplicate tracks."
    # Figure out if the inputs of applied_protocols in a particular column differ
    tracks_per_column = Hash.new
    values_per_column = Hash.new
    (0...column).each do |col|
      tracks_per_column[col] = applied_protocols.values.find_all { |ap| ap.column == col }.map { |ap| ap.inputs.sort }.uniq.size
      values_per_column[col] = applied_protocols.values.find_all { |ap| ap.column == col }.map { |ap| ap.inputs.sort }.flatten.uniq
      if (col == column-1) then
        values_per_column[col+1] = applied_protocols.values.find_all { |ap| ap.column == col }.map { |ap| ap.outputs.sort }.flatten.uniq
      end
    end

    # Filter values_per_column so we only keep things that could be separate tracks (e.g. GFF, SAM, WIG)
    sth_is_a_track = dbh_safe { @dbh.prepare("SELECT COUNT(feature_id) FROM data_feature WHERE data_id = ?") }
#    cmd_puts "Values per column:\n#{values_per_column.pretty_inspect.gsub('<', '&lt;').gsub('>', '&gt;')}"
    values_per_column.each { |k, v|
      v.delete_if { |data_id|
        dbh_safe { sth_is_a_track.execute(data_id) }
        row = dbh_safe { sth_is_a_track.fetch }
        row[0] == 0
      }
    }
    values_per_column.each { |k, v| values_per_column[k] = [] if v.size > TRACKS_PER_COLUMN }
    standalone_tracks = values_per_column.values.flatten.uniq.map { |data_id|
      # Find any applied protocols that use this 
      aps = applied_protocols.values.find_all { |ap| ap.inputs.include?(data_id) }
      aps = applied_protocols.values.find_all { |ap| ap.outputs.include?(data_id) } if aps.size == 0
      aps.map { |ap|
        AppliedProtocol.new(
          :applied_protocol_id => ap.applied_protocol_id,
          :inputs => [ data_id ],
          :protocols => ap.protocols
        )
      }
    }

#    cmd_puts "Applied protocols example:\n#{tracks_per_column.pretty_inspect.gsub('<', '&lt;').gsub('>', '&gt;')}"
#    cmd_puts "Values per column:\n#{values_per_column.pretty_inspect.gsub('<', '&lt;').gsub('>', '&gt;')}"
#    cmd_puts "Standalone tracks:\n#{standalone_tracks.pretty_inspect.gsub('<', '&lt;').gsub('>', '&gt;')}"

    # For each column, figure out what to do based on the number of possible tracks
    # found for that column
    data_names = Hash.new

    sth_data_names = dbh_safe { @dbh.prepare("SELECT heading, name FROM data WHERE data_id = ?") }
    tracks_per_column.sort_by { |column, number_of_tracks| column }.each do |column, number_of_tracks|
      # Get all the applied_protocols for this column
      cur_aps = applied_protocols.values.find_all { |ap| ap.column == column } 

      # Flip the tracks around so we can see which inputs come from which tracks
      tracks_by_input = Hash.new { |hash, key| hash[key] = Array.new }
      cur_aps.each { |ap| ap.inputs.each { |input| tracks_by_input[input].push ap } }

      # Get the headings of each datum to actually tie them together
      tracks_by_input.each_key do |data_id|
        dbh_safe { sth_data_names.execute(data_id) }
        row = dbh_safe { sth_data_names.fetch }
        row[0] = "Anonymous Datum" if (row[0] =~ /^Anonymous Datum #/)
        data_names[data_id] = "#{row[0]} [#{row[1]}]"
      end

      if number_of_tracks > TRACKS_PER_COLUMN then
        cmd_puts "      #{cur_aps[0].protocols.map { |p| p[:name] }.join(", ")} has #{number_of_tracks} potential distinct tracks; attempting to combine applied protocols."

        # Get all the inputs for tracks that collapse
        inputs_that_collapse = tracks_by_input.reject { |k, v| number_of_tracks/v.size > TRACKS_PER_COLUMN }
        full_collapse_inputs = inputs_that_collapse.reject { |k, v| number_of_tracks != v.size }
        full_collapse_inputs.each do |data_id, aps|
          cmd_puts "        Could collapse all applied protocols for protocol '#{aps[0].protocols.map { |p| p[:name] }.join(", ")}' into one set of track(s) by shared '#{data_names[data_id]}'"
        end

        partial_collapse_inputs = Hash.new { |hash, key| hash[key] = Array.new }
        inputs_that_collapse.reject { |data_id, aps| number_of_tracks == aps.size }.each { |data_id, aps|
          partial_collapse_inputs[data_names[data_id]].push aps
        }

        # If this is the last protocol, check to see the output can be collapsed, too, before we get carried away collapsing based on inputs
        if column == tracks_per_column.keys.max  then
          tracks_by_output = Hash.new { |hash, key| hash[key] = Array.new }
          cur_aps.each { |ap| ap.outputs.each { |output| tracks_by_output[output].push ap } }

          tracks_by_output.each_key do |data_id|
            dbh_safe { sth_data_names.execute(data_id) }
            row = dbh_safe { sth_data_names.fetch }
            row[0] = "Anonymous Datum" if (row[0] =~ /^Anonymous Datum #/)
            data_names[data_id] = "#{row[0]} [#{row[1]}]"
          end
          if (partial_collapse_inputs.size > 0) && (tracks_by_output.keys.size > 0) then # && (tracks_by_output.reject { |k, v| number_of_tracks/v.size > TRACKS_PER_COLUMN }.keys.size == 0) then
            # Have outputs that don't collapse
            partial_collapse_inputs = Hash.new { |hash, key| hash[key] = Array.new }
          end
        end

        # TODO: If could do a partial collapse on an anonymous datum, then work back up the protocol chain
        # and find out where the difference _does_ occur
        partial_collapse_inputs.each do |data_name, aps|
          cmd_puts "        Could collapse all applied protocols for protocol '#{aps[0][0].protocols.map { |p| p[:name] }.join(", ")}' into #{aps.size} tracks by shared '#{data_name}'"
        end

        # TODO: Replace this with above todo
        #partial_collapse_inputs.reject! { |data_name, aps| data_name =~ /^Anonymous Datum/ }

        if partial_collapse_inputs.size == 0 && full_collapse_inputs.size > 0 then
          cmd_puts "      Cannot do a partial collapse (w/o anonymous inputs), so assuming all applied protocols in position #{column} should generate just one set of track(s) per column of data."
          usable_tracks[column].push cur_aps
        elsif partial_collapse_inputs.size > 0 then
          # Pick the partial input that we're going to use to divide up the tracks
          # TODO: Pick the partial input smarter
          selected_dividing_datum = partial_collapse_inputs.keys[0]
          cmd_puts "      Collapsing into #{partial_collapse_inputs[selected_dividing_datum].size} set(s) of track(s)"
          usable_tracks[column] = usable_tracks[column] + partial_collapse_inputs[selected_dividing_datum]
        else
          # No inputs allow collapsing (either in part or total) so just collapse the whole thing on principle
          cmd_puts "      Creating 1 set(s) of track(s) for protocol '#{cur_aps[0].protocols.map { |p| p[:name] }.join(", ")}'; there is no way to collapse by input."
          usable_tracks[column].push cur_aps
        end
      else
        cmd_puts "      Creating #{number_of_tracks} set(s) of track(s) for protocols '#{cur_aps[0].protocols.map { |p| p[:name] }.join(", ")}'"
        usable_tracks[column].push cur_aps
      end
    end
    dbh_safe { sth_data_names.finish }

    col = usable_tracks.keys.max
    usable_tracks = usable_tracks.map { |k, v| [k, v] }
    standalone_tracks.each { |aps|
      col += 1
      aps.each { |ap| ap.column = col }
      usable_tracks.push [ col, [aps.map { |ap| ap }], true ]
    }

    cmd_puts "\n      " + (usable_tracks.sort_by { |col, set_of_tracks| col }.map { |col, set_of_tracks| "Protocol #{col} has #{set_of_tracks.size} set(s) of potential track(s)" }.join(", "))
    cmd_puts "    Done."


    return usable_tracks
  end
  def attach_generic_metadata(ap_ids, experiment_id, project_id, protocol_ids_by_column)
    tracknum = self.get_next_tracknum
    history_depth = 0
    while ap_ids.size > 0
      prev_ap_ids = Array.new
#      dbh_safe {
        seen = Hash.new
        if history_depth == 0 then
          # Still at the protocol that makes these tracks, so check for sibling outputs
          @sth_metadata_last.execute(ap_ids.size, ap_ids)
          @sth_metadata_last.fetch do |row|
            unless row['data_value'].nil? || row['data_value'].empty? || seen[row['data_value']] then
              # Datum name
              seen[row['data_value']] = true
#              begin
                rowval = row['data_value'].nil? ? nil : row['data_value'][0...250],
                TrackTag.new(
                  :experiment_id => experiment_id,
                  :name => rowval,
                  :project_id => project_id,
                  :track => tracknum,
                  :value => rowval,
                  :cvterm => row['data_type'],
                  :history_depth => history_depth
                ).save
#              rescue
#              end
              # Datum URL prefix (for wiki links)
#              begin
                TrackTag.new(
                  :experiment_id => experiment_id,
                  :name => rowval,
                  :project_id => project_id,
                  :track => tracknum,
                  :value => row['db_url'],
                  :cvterm => 'data_url',
                  :history_depth => history_depth
                ).save unless row['db_type'] != "URL_mediawiki_expansion"
#              rescue
#              end
            end
            # Datum attributes
            begin
              TrackTag.new(
                :experiment_id => experiment_id,
                :name => row['data_value'],
                :project_id => project_id,
                :track => tracknum,
                :value => row['attr_value'],
                :cvterm => row['attr_name'],
                :history_depth => history_depth
              ).save unless row['attr_value'].nil? || row['attr_value'].empty?
            rescue
            end
          end
        end
        # Get all of the metadata leading up to this protocol
        @sth_metadata.execute(ap_ids)
        @sth_metadata.fetch do |row|
            unless row['data_value'].nil? || row['data_value'].empty? || seen[row['data_value']] then
              seen[row['data_value']] = true
              # Datum name
#              begin
                rowval = row['data_value'].nil? ? nil : row['data_value'][0...250],
                TrackTag.new(
                  :experiment_id => experiment_id,
                  :name => rowval,
                  :project_id => project_id,
                  :track => tracknum,
                  :value => rowval,
                  :cvterm => row['data_type'],
                  :history_depth => history_depth
                ).save
#              rescue
#              end
              # Datum URL prefix (for wiki links)
#              begin
                TrackTag.new(
                  :experiment_id => experiment_id,
                  :name => rowval,
                  :project_id => project_id,
                  :track => tracknum,
                  :value => row['db_url'],
                  :cvterm => 'data_url',
                  :history_depth => history_depth
                ).save unless row['db_type'] != "URL_mediawiki_expansion"
#              rescue
#              end
              # Datum attributes
            end
            begin
              TrackTag.new(
                :experiment_id => experiment_id,
                :name => row['data_value'],
                :project_id => project_id,
                :track => tracknum,
                :value => row['attr_value'],
                :cvterm => row['attr_name'],
                :history_depth => history_depth
              ).save unless row['attr_value'].nil? || row['attr_value'].empty?
            rescue
            end
            # And go through any attached previous applied protocols
            prev_ap_ids.push row['prev_applied_protocol_id'] unless row['prev_applied_protocol_id'].nil?
        end
        # Get all of the metadata that comes out of this protocol and terminates
        @sth_leaf_metadata.execute(ap_ids)
        @sth_leaf_metadata.fetch do |row|
            unless row['data_value'].nil? || row['data_value'].empty? || seen[row['data_value']] then
              seen[row['data_value']] = true
              # Datum name
#              begin
                TrackTag.new(
                  :experiment_id => experiment_id,
                  :name => row['data_value'],
                  :project_id => project_id,
                  :track => tracknum,
                  :value => row['data_value'],
                  :cvterm => row['data_type'],
                  :history_depth => history_depth
                ).save
#              rescue
#              end
              # Datum URL prefix (for wiki links)
#              begin
                TrackTag.new(
                  :experiment_id => experiment_id,
                  :name => row['data_value'],
                  :project_id => project_id,
                  :track => tracknum,
                  :value => row['db_url'],
                  :cvterm => 'data_url',
                  :history_depth => history_depth
                ).save unless row['db_type'] != "URL_mediawiki_expansion"
#              rescue
#              end
              # Datum attributes
            end
            begin
              TrackTag.new(
                :experiment_id => experiment_id,
                :name => row['data_value'],
                :project_id => project_id,
                :track => tracknum,
                :value => row['attr_value'],
                :cvterm => row['attr_name'],
                :history_depth => history_depth
              ).save unless row['attr_value'].nil? || row['attr_value'].empty?
            rescue
            end
            # And go through any attached previous applied protocols
            prev_ap_ids.push row['prev_applied_protocol_id'] unless row['prev_applied_protocol_id'].nil?
        end
#      }
      ap_ids = prev_ap_ids.uniq
      history_depth = history_depth + 1
    end

    ### Citation stuff ###
    # Experiment properties
#    dbh_safe {
      sth_idf_info = @dbh.prepare "SELECT ep.name, ep.value, ep.rank, c.name AS type FROM experiment_prop ep 
                                   INNER JOIN cvterm c ON ep.type_id = c.cvterm_id 
                                   WHERE experiment_id = ?
                                   GROUP BY ep.name, ep.value, ep.rank, c.name"
      sth_idf_info.execute(experiment_id)
      sth_idf_info.fetch do |row|
#        begin
          TrackTag.new(
            :experiment_id => experiment_id,
            :name => row['name'],
            :project_id => project_id,
            :track => tracknum,
            :value => row['value'],
            :cvterm => row['type'],
            :history_depth => row['rank']
          ).save
#        rescue
#        end
      end
      sth_idf_info.finish
#    }

    # Any referenced submissions
#    dbh_safe {
      sth_idf_info = @dbh.prepare "SELECT DISTINCT url FROM db WHERE description = 'modencode_submission'"
      sth_idf_info.execute
      rank = 0
      sth_idf_info.fetch do |row|
#        begin
          TrackTag.new(
            :experiment_id => experiment_id,
            :name => "Referenced Submission",
            :project_id => project_id,
            :track => tracknum,
            :value => row['url'],
            :cvterm => "referenced_submission",
            :history_depth => rank
          ).save
#        rescue
#        end
        rank += 1
      end
      sth_idf_info.finish
#    }

    # Protocol types and names and links
#    dbh_safe {
      sth_protocol_type = @dbh.prepare "SELECT p.protocol_id, p.name, a.value AS type, dbx.accession AS url FROM attribute a 
              INNER JOIN protocol_attribute pa ON a.attribute_id = pa.attribute_id 
              INNER JOIN protocol p ON pa.protocol_id = p.protocol_id 
              LEFT JOIN dbxref dbx ON p.dbxref_id = dbx.dbxref_id
              WHERE a.heading = 'Protocol Type' AND p.protocol_id = ANY(?)
              GROUP BY p.protocol_id, p.name, type, url"

      seen = { :value => Hash.new, :name => Hash.new }
      protocol_ids_by_column.to_a.sort { |p1, p2| p1[0] <=> p2[0] }.each do |col, protocol_ids|
        sth_protocol_type.execute(protocol_ids)
        sth_protocol_type.fetch do |row|
          unless seen[:value][row["value"]] && seen[:name][row["name"]] then
            seen[:value][row["value"]] = true
            seen[:name][row["name"]] = true
#          begin
            TrackTag.new(
              :experiment_id => experiment_id,
              :name => row['name'],
              :project_id => project_id,
              :track => tracknum,
              :value => row['type'],
              :cvterm => 'protocol_type',
              :history_depth => col
            ).save
#          rescue
#          end
#          begin
            TrackTag.new(
              :experiment_id => experiment_id,
              :name => row['name'],
              :project_id => project_id,
              :track => tracknum,
              :value => row['url'],
              :cvterm => 'protocol_url',
              :history_depth => col
            ).save
#          rescue
#          end
          end
        end
      end
      sth_protocol_type.finish
#    }

    return tracknum
  end
  def generate_track_files_and_tags(experiment_id, project_id, output_dir)
    cmd_puts "Loading feature and wiggle data into GBrowse database..."

    ########## Get Usable Tracks #########
    cmd_puts "  Detecting tracks included in submission."

    # Get datum objects attached to features or wiggle data
    usable_tracks = find_usable_tracks(experiment_id, project_id)
    cmd_puts "    Found usable tracks; sorting."
    return nil if usable_tracks.nil?
    # Figure out the protocol order
    protocol_ids_by_column = Hash.new {|h, k| h[k] = Array.new }
    usable_tracks.each { |col, set_of_tracks, standalone_track| 
      protocol_ids_by_column[col] = set_of_tracks.first.map { |ap| ap.protocols.map { |p| p[:id] } }.uniq
    }

    tracknum_to_data_name = Hash.new

    cmd_puts "  Done."
    ######### /Get Usable Tracks #########
    ######## Find Features/Wiggles #######

    seen_wiggles = Array.new
    seen_sams = Array.new

    cmd_puts "  Finding features, wiggle files, and SAM files attached to tracks."
    found_any_tracks = false
#    cmd_puts "Usable tracks:\n#{usable_tracks.pretty_inspect.gsub('<', '&lt;').gsub('>', '&gt;')}"
    usable_tracks.each do |col, set_of_tracks, standalone_track|
      cmd_puts "    For the protocol in column #{col}, with #{set_of_tracks.size} possible tracks:"
      set_of_tracks.each do |applied_protocols|
        # Get the data objects for the applied protocol
        ap_ids = applied_protocols.map { |ap| ap.applied_protocol_id }

        data_ids_with_features = Array.new
        data_ids_with_wiggles = Array.new
        data_ids_with_sam_files = Array.new

        if standalone_track then
          data_ids_with_features = applied_protocols.map { |ap| ap.inputs }.flatten.uniq
        else
          dbh_safe {
            @sth_get_data_by_applied_protocols.execute(ap_ids)
            @sth_get_data_by_applied_protocols.fetch_hash do |row|
              if row['number_of_features'].to_i > 0 then
                data_ids_with_features.push row["data_id"].to_i
              elsif row['number_of_wiggles'].to_i > 0 then
                data_ids_with_wiggles.push row["data_id"].to_i
              elsif ( row['type'] == "Sequence_Alignment/Map (SAM)" ||
                      row['type'] == "Binary Sequence_Alignment/Map (BAM)" ) then
                data_ids_with_sam_files.push row["data_id"]
              end
            end
          }
        end

        # No need to continue if there isn't anything to make tracks of
        if data_ids_with_wiggles.size <= 0 && data_ids_with_features.size <= 0 && data_ids_with_sam_files.size <= 0 then
          cmd_puts "      There are no features, wiggle files, or SAM files for this potential track."
          next
        end
        found_any_tracks = true

        if data_ids_with_features.size > 0 then
          # Get any features associated with this track's data objects
          cmd_puts "      Getting features."
          cmd_puts "        Finding metadata for features."
          tracknum = attach_generic_metadata(ap_ids, experiment_id, project_id, protocol_ids_by_column)
          cmd_puts "          Using tracknum #{tracknum}"
          cmd_puts "        Done."

          if (standalone_track && data_ids_with_features.size == 1) then
            # Record this filename in a tracktag so we can differentiate files when configging tracks
            @sth_get_data_value_by_data_id.execute(data_ids_with_features.first)
            gff_filename = @sth_get_data_value_by_data_id.fetch[0]
            TrackTag.new(
              :experiment_id => experiment_id,
              :name => 'GFF File',
              :project_id => project_id,
              :track => tracknum,
              :value => gff_filename,
              :cvterm => 'gff_file',
              :history_depth => 0
            ).save
          end

          analyses = Hash.new
          organisms = Hash.new
          features_processed = 0 # Track number of features to determine if we want a wiggle file

          # Open GFF file for writing
          Dir.mkdir(output_dir) unless File.directory? output_dir
          gff_sqlite = DBI.connect("dbi:SQLite3:#{File.join(TrackFinder::gbrowse_tmp, "#{tracknum}_tracks.sqlite")}")
          gff_sqlite.do("PRAGMA temp_store = 1")
          gff_sqlite.do("PRAGMA synchronous = OFF")
          gff_sqlite.do("CREATE TABLE gff (id INTEGER PRIMARY KEY, feature_id INTEGER UNIQUE, gff_string TEXT, parents TEXT, srcfeature VARCHAR(255), type VARCHAR(255), fmin INTEGER, fmax INTEGER)")
          gff_sqlite.do("BEGIN TRANSACTION")
          sth_add_gff = gff_sqlite.prepare("INSERT INTO gff (feature_id, gff_string, parents, srcfeature, type, fmin, fmax) VALUES(?, ?, ?, ?, ?, ?, ?)")
          sth_get_gff = gff_sqlite.prepare("SELECT gff_string, parents FROM gff WHERE feature_id = ?")
          sth_get_all_gff = gff_sqlite.prepare("SELECT srcfeature, type, fmin, fmax FROM gff")
          sth_set_gff_parent = gff_sqlite.prepare("UPDATE gff SET parents = ? WHERE feature_id = ?")

          cmd_puts "        Getting top-level features."
          seen_feature_ids = Hash.new
          parent_feature_ids = Hash.new
          chromosome_located_features = false
          parsed_features = 0
          dbh_safe {
            data_ids_with_features.uniq!
            @sth_get_features_by_data_ids.execute data_ids_with_features.size, data_ids_with_features
            @sth_get_features_by_data_ids.fetch_hash { |row|
              tracknum_to_data_name[tracknum] = row.delete('data_name')
              next if seen_feature_ids[row['feature_id']]

              @sth_get_featurelocs_by_feature_id.execute(row["feature_id"])
              loc_rows = @sth_get_featurelocs_by_feature_id.fetch_all
              loc_rows = loc_rows.map { |loc_row| loc_row.nil? ? {} : loc_row.to_h }
              next if loc_rows.find { |loc_row| loc_row['fmin'] || loc_row['fmax'] }.nil?  # Skip features with no location

              parent_feature_ids[row['feature_id']] = true
              seen_feature_ids[row['feature_id']] = true

              @sth_get_analysisfeatures_by_feature_id.execute(row["feature_id"])
              af_row = @sth_get_analysisfeatures_by_feature_id.fetch
              af_row = af_row.nil? ? {} : af_row.to_h

              current_feature_hash = row.merge(loc_rows[0]).merge(af_row)
              if loc_rows.size > 1 then
                tgt_row = loc_rows[1]
                current_feature_hash['target'] = "#{tgt_row['srcfeature']} #{tgt_row['fmin'].to_i+1} #{tgt_row['fmax']}"
                current_feature_hash['target_accession'] = "#{tgt_row['srcfeature_accession']}"
                current_feature_hash['gap'] = tgt_row['residue_info'] if tgt_row['residue_info']
              end

              current_feature_hash['properties'] = Hash.new { |props, prop| props[prop] = Hash.new }
              @sth_get_featureprops_by_feature_id.execute(row["feature_id"])
              @sth_get_featureprops_by_feature_id.fetch_hash { |fp_row|
                current_feature_hash['properties'][fp_row['propname']][fp_row['proprank'].to_i] = fp_row['propvalue'] unless fp_row['propvalue'].nil?
              }

              current_feature_hash['parents'] = Array.new # Top level features have no parents

              parsed_features += 1
              cmd_puts "          Parsed #{parsed_features} features." if parsed_features % 2000 == 0
              # Record metadata
              chromosome_located_features = true if !current_feature_hash['srcfeature_id'].nil? && current_feature_hash['srcfeature_id'] != current_feature_hash['feature_id']
              analyses[current_feature_hash['analysis']] = true unless current_feature_hash['analysis'].nil?
              organisms[current_feature_hash['genus'] + " " + current_feature_hash['species']] = true unless current_feature_hash['genus'].nil?

              # Write feature to temp sqlite db
              if parsed_features % 2000 == 0 then
                gff_sqlite.do("END TRANSACTION")
                gff_sqlite.do("BEGIN TRANSACTION")
              end
              sth_add_gff.execute(
                current_feature_hash['feature_id'], 
                feature_to_gff(current_feature_hash.dup, tracknum), 
                      '',
                      current_feature_hash['srcfeature'],
                      current_feature_hash['type'],
                      current_feature_hash['fmin'],
                      current_feature_hash['fmax']
              )
            }
          }
          cmd_puts "        Done fetching top-level features."

          # Child features
          parsed_features = 0
          if there_are_feature_relationships? && parent_feature_ids.size > 0 then
            cmd_puts "        Getting child features."
            round = 1
            while parent_feature_ids.size > 0 do
              cmd_puts "        Recursing child features at level #{round}, with #{parent_feature_ids.size} parent features"
              round += 1

              dbh_safe {
                @sth_get_parts_of_features.execute parent_feature_ids.size, parent_feature_ids.keys
                row = @sth_get_parts_of_features.fetch_hash
                parents = Array.new
                parent_feature_ids = Hash.new
                current_feature_hash = nil
                while (!row.nil?) do
                  current_feature_hash = row
                  current_feature_hash['parents'] = Array.new
                  break if current_feature_hash['feature_id'] == -1 # Only happens if no results

                  # Get all the parent feature IDs
                  while (!row.nil? && row["feature_id"] == current_feature_hash["feature_id"]) do
                    current_feature_hash['parents'].push [row['relationship_type'], row['parent_id']] if row['parent_id']
                    row = @sth_get_parts_of_features.fetch_hash
                  end
                  current_feature_hash['parents'] = current_feature_hash['parents'].map { |reltype, parent| "#{reltype}/#{parent}" }.join(',')

                  parsed_features += 1
                  cmd_puts "          Parsed #{parsed_features} features." if parsed_features % 2000 == 0

                  if seen_feature_ids[current_feature_hash['feature_id']] then
                    cmd_puts "Setting parents, but not updating anything else for #{current_feature_hash['feature_id']}, seen it" if @debugging
                    sth_set_gff_parent.execute(current_feature_hash['parents'], current_feature_hash['feature_id'])
                    next # We've seen this feature before and don't yet support relationship loops
                  end
                  seen_feature_ids[current_feature_hash['feature_id']] = true

                  # Record that we've seen this feature and can use it as a parent of other features (e.g. we started with genes, and this is a transcript)
                  parent_feature_ids[current_feature_hash['feature_id']] = true

                  # Get any locations for this feature and attach them to the object
                  @sth_get_featurelocs_by_feature_id.execute(current_feature_hash["feature_id"])
                  loc_rows = @sth_get_featurelocs_by_feature_id.fetch_all.map { |loc_row| loc_row.nil? ? {} : loc_row.to_h }
                  if (loc_rows.size == 0 || loc_rows.find { |loc_row| loc_row['fmin'] || loc_row['fmax'] }.nil?) then
                    cmd_puts "Skipping #{current_feature_hash['feature_id']}, it has no locations" if @debugging
                    next # Skip features with no location 
                  end
                  current_feature_hash.merge(loc_rows[0]) # Attach the location info to this feature


                  # Get analysisfeature and thus scores for this feature
                  @sth_get_analysisfeatures_by_feature_id.execute(current_feature_hash["feature_id"])
                  af_row = @sth_get_analysisfeatures_by_feature_id.fetch
                  af_row = af_row.nil? ? {} : af_row.to_h
                  current_feature_hash = current_feature_hash.merge(af_row) # Attach the analysis info to this feature

                  # If there's a second location, then it's for a target feature
                  if loc_rows.size > 1 then
                    tgt_row = loc_rows[1]
                    current_feature_hash['target'] = "#{tgt_row['srcfeature']} #{tgt_row['fmin'].to_i+1} #{tgt_row['fmax']}"
                    current_feature_hash['target_accession'] = "#{tgt_row['srcfeature_accession']}"
                    current_feature_hash['gap'] = tgt_row['residue_info'] if tgt_row['residue_info']
                  end

                  # Get feature properties
                  current_feature_hash['properties'] = Hash.new { |props, prop| props[prop] = Hash.new }
                  @sth_get_featureprops_by_feature_id.execute(current_feature_hash["feature_id"])
                  @sth_get_featureprops_by_feature_id.fetch_hash { |fp_row|
                    current_feature_hash['properties'][fp_row['propname']][fp_row['proprank'].to_i] = fp_row['propvalue'] unless fp_row['propvalue'].nil?
                  }

                  # Make sure that at least one feature is located to the chromosome
                  chromosome_located_features = true if !current_feature_hash['srcfeature_id'].nil? && current_feature_hash['srcfeature_id'] != current_feature_hash['feature_id']

                  # Keep track of which analyses and organisms we've seen
                  analyses[current_feature_hash['analysis']] = true unless current_feature_hash['analysis'].nil?
                  organisms[current_feature_hash['genus'] + " " + current_feature_hash['species']] = true unless current_feature_hash['genus'].nil?

                  cmd_puts "Set feature parents to #{current_feature_hash["parents"]}"
                  sth_add_gff.execute(
                                      current_feature_hash['feature_id'], 
                                      feature_to_gff(current_feature_hash.dup, tracknum), 
                                      current_feature_hash['parents'],
                                      current_feature_hash['srcfeature'],
                                      current_feature_hash['type'],
                                      current_feature_hash['fmin'],
                                      current_feature_hash['fmax']
                                     )
                end
              }
            end
            cmd_puts "        Done getting #{parsed_features} child features."
          end

          # Track the unique analyses used in this track so we can
          # color by them in the configure_tracks page
          analyses.keys.each { |analysis|
            TrackTag.new(
              :experiment_id => experiment_id,
              :name => 'Analysis',
              :project_id => project_id,
              :track => tracknum,
              :value => analysis,
              :cvterm => 'unique_analysis',
              :history_depth => 0
            ).save
          }
          # Track the unique organisms used in this track so we can
          # guess which GBrowse configuration to use
          organisms.keys.each { |organism|
            TrackTag.new(
              :experiment_id => experiment_id,
              :name => 'Organism',
              :project_id => project_id,
              :track => tracknum,
              :value => organism,
              :cvterm => 'organism',
              :history_depth => 0
            ).save
          }
          # Label this as a feature track
          TrackTag.new(
            :experiment_id => experiment_id,
            :name => 'Track Type',
            :project_id => project_id,
            :track => tracknum,
            :value => 'feature',
            :cvterm => 'track_type',
            :history_depth => 0
          ).save


          # Write out a GFF and wiggle only if they're actually going to contain anything useful
          if chromosome_located_features then
            gff_file = File.new(File.join(output_dir, "#{tracknum}.gff"), "w")
            gff_file.puts "##gff-version 3"
            cmd_puts "        Creating GFF file."
            while seen_feature_ids.size > 0
              recursive_output(seen_feature_ids, sth_get_gff, gff_file)
            end
            gff_file.close

            # Generate a wiggle file (bigwig)
            cmd_puts "        Generating a bigwig file for zoomed-out views."
            sth_get_all_gff.execute
            
            wiggle_writers = Hash.new { |hash, types|
              hash[types] = Hash.new { |typehash, chrom|
                typehash[chrom] = [] # This array will contain the bedGraph lines for that chromosome & type.
              }
            }
            poss_organisms = CHROMOSOMES.keys
            got_organism = false
            seen_chroms = []
            sth_get_all_gff.fetch_hash { |row|
              if row['fmin'] && row['fmax'] && CHROMOSOMES.values.flatten.include?(row['srcfeature']) then
                # Attempt to infer organism
                unless (got_organism || ( seen_chroms.include? row['srcfeature'] )) then 
                  poss_organisms, got_organism = eliminate_organisms(poss_organisms, row['srcfeature']) 
                  seen_chroms.push row['srcfeature']
                end
                # Add the row to the bed array
                # Note that when writing for wigdb, the start and end coords were fmin+1 and fmax;
                # so we can infer that the plain fmin is 0-based; our only formats are 0-based
                # half open and one-based ; fmax will be the same either way. Therefore, we can 
                # use plain fmin and fmax when writing the bedGraph.
                current_bed = wiggle_writers[row['type']][row['srcfeature']]
                #current_bed.push "#{row['srcfeature']}\t#{(row['fmin'].to_i).to_s}\t#{row['fmax']}\t255"
                current_bed.push [ row['srcfeature'], row['fmin'].to_i, row['fmax'].to_i, 255 ]
              end
            }

            wiggle_writers.each { |type, chrs|
              # For each type, make a bedfile of the chrs in order
              collected_bed = Tempfile.new("#{tracknum}_#{type}.bed", TrackFinder::gbrowse_tmp)
              chrs.each { |chrom, bed_array|
                # Sort the array of BED lines by fmin
                bed_array.sort! { |a, b| a[1] <=> b[1] }
                # Merge any overlapping features
                bed_array = bed_array.reduce(Array.new) { |list, line|
                  last_line = list.last
                  if last_line && last_line[2] >= line[1] then
                    last_line[2] = line[2] # Combine overlapping features
                  else
                    list.push line
                  end
                  list
                }
                # Write lines
                bed_array.each { |line| collected_bed.puts line.join("\t") }
              }

              # Then write the bigwig. 
              collected_bed.close
              if got_organism then
                chrom_file = organism_to_chromfile(got_organism)

                # Store the bigwig in the output dir specified in the gen tf and tags function call
                bigwig_path = File.join(output_dir, "#{tracknum}_#{type}.bw")

                # The bigwig will never be in a subdirectory, so there's no need to try & find one
                # When we're making the TrackTag, just use the basename instead of full path (?)
                wrote_bigwig = convert_to_bigwig(collected_bed.path, chrom_file, bigwig_path)
                unless wrote_bigwig then
                  cmd_puts "          Failed to create bigwig file #{bigwig_path}."
                  next
                end
                cmd_puts "          Wrote BigWig file #{bigwig_path}." if debugging?
                # Bigwig path should be

                # Then add a track tag so we can find the type again
                TrackTag.new(
                  :experiment_id => experiment_id,
                  :name => "BigWig File #{type}",
                  :project_id => project_id,
                  :track => tracknum,
                  :value => File.basename(bigwig_path),
                  :cvterm => 'bigwig_file',
                  :history_depth => 0
                ).save 
                TrackTag.new(
                  :experiment_id => experiment_id,
                  :name => 'Feature Type',
                  :project_id => project_id,
                  :track => tracknum,
                  :value => type,
                  :cvterm => "feature_type",
                  :history_depth => 0
                ).save
              end
              collected_bed.unlink     
            }

            cmd_puts "        Done."
            cmd_puts "      Done."
          end

          sth_get_gff.finish
          sth_get_all_gff.finish
          sth_add_gff.finish
          sth_set_gff_parent.finish
          gff_sqlite.disconnect

          File.unlink(File.join(TrackFinder::gbrowse_tmp, "#{tracknum}_tracks.sqlite"))

          cmd_puts "      Done getting features."
        end
        if data_ids_with_wiggles.size > 0 then
          cmd_puts "      Getting wiggle files."
          dbh_safe {
            @sth_get_wiggles_by_data_ids.execute data_ids_with_wiggles.uniq
            @sth_get_wiggles_by_data_ids.fetch_hash { |row|
              next if seen_wiggles.include?(row["wiggle_data_id"])
              wiggle_filename = row["data_value"]
              seen_wiggles.push row["wiggle_data_id"]
              cmd_puts "        Finding metadata for wiggle files."
              tracknum = attach_generic_metadata(ap_ids, experiment_id, project_id, protocol_ids_by_column)
              cmd_puts "          Using tracknum #{tracknum}"
              cmd_puts "        Done."
              # Write out the current wiggle
              # bigwig_file_path gets used for writing the TrackTag, but really the bigwig gets written
              # into a tempdir and then *moved* to output_dir -- so if that code is changed (eg to allow
              # it to be moved to a subdir instead) this path should be changed too.
              bigwig_file_path = File.join(output_dir, "#{tracknum}.bw")
              bigwig_tmp_file_path = File.join(TrackFinder::gbrowse_tmp, "#{tracknum}.bw")
              cmd_puts "    Writing bigwig file to: #{bigwig_tmp_file_path}"
              
              # Put the wiggle in a temp file for parsing
              # BigWig can't handle wiggles with span > distance between values, so
              # make a temporary .bed for all wiggles with spans.
 
              # Get the source wiggle file
              unless row["cleaned_wiggle_file"] then
                
                wiggle_tempfile = Tempfile.new('wiggle_file', TrackFinder::gbrowse_tmp)
                # TEMP FIXME : save the file so i can look at it later. real line above.
                #tmp_tmpdir = "/users/ekephart/tmp"
                #wiggle_tempfile = File.new(File.join(tmp_tmpdir, 'wiggle_file'), "w")
                wiggle_tempfile.puts row['wiggle_file']
                wiggle_tempfile.close
                source_wiggle_file = File.open(wiggle_tempfile.path, "r") # Open it as a regular file for reading
              else
                source_wiggle_file_path = File.join(ExpandController.path_to_project_dir(Project.find(project_id)), "extracted", row["cleaned_wiggle_file"])
                source_wiggle_file = File.open(source_wiggle_file_path, "r")
              end
                 
              # And get the name for more-informative error messages
              source_wiggle_name = row['name']
              # Then, convert source_wiggle_file to bed if necessary
              # Create temp file to put the bed in
              bed_file = Tempfile.new('bed_file', TrackFinder::gbrowse_tmp)
              # Then, run the convert tool to convert the wiggle into a bed if necessary
              # Also get the organism via chromosome names
              bed_cvt_failed, original_wig_ok, wig_organism = convert_wiggle_to_bed(source_wiggle_file,
                                                                                    bed_file, 
                                                                                    source_wiggle_name  )

              bed_file.close 
              source_wiggle_file.close
              # Get chromosome file for bigwig conversion unless we've already failed anyways
              chrom_file_path = bed_cvt_failed ? false : organism_to_chromfile(wig_organism)              
              # Conversion failed or no organism found - die
              if bed_cvt_failed || ! chrom_file_path then
                bed_file.unlink
                wiggle_tempfile.unlink unless row["cleaned_wiggle_file"]

                cmd_puts "    Failed to convert #{source_wiggle_name} at #{source_wiggle_file.path} to bedGraph--cannot proceed with bigWig conversion for this track!" if bed_cvt_failed
                # Not having a chromfile complained already in organism_to_chromfile
                return # TrackFinding will fail
              end
              
              source_for_bigwig = original_wig_ok ? source_wiggle_file : bed_file
              bigwig_written = convert_to_bigwig(source_for_bigwig.path, chrom_file_path, bigwig_tmp_file_path)
              unless bigwig_written then
                cmd_puts "    Failed to create bigwig file at #{bigwig_tmp_file_path}."
                return
              end

              # Remove the temporary source files
              unless row["cleaned_wiggle_file"] then
                wiggle_tempfile.unlink # unless debugging?
              end
              bed_file.unlink # unless debugging?

              # Move the output file to the output_dir
              wildcard_tmp = sprintf(bigwig_tmp_file_path, "*")
              cmd_puts "        Moving #{wildcard_tmp} to #{output_dir}."
              Dir.glob(wildcard_tmp).each { |filename|
                File.dirname(wildcard_tmp)
                # Output here is misleading & unncessary as with bigwigs this should only loop once anyhow
                # cmd_puts "          Moving file #{filename} to #{File.join(output_dir, filename)}"
                FileUtils.mv(filename, output_dir)
              }
              cmd_puts "        Done."
              # Label this as a wiggle track
              TrackTag.new(
                :experiment_id => experiment_id,
                :name => 'Wiggle File',
                :project_id => project_id,
                :track => tracknum,
                :value => wiggle_filename,
                :cvterm => 'wiggle_file',
                :history_depth => 0
              ).save
              TrackTag.new(
                :experiment_id => experiment_id,
                :name => 'Track Type',
                :project_id => project_id,
                :track => tracknum,
                :value => 'bigwig',
                :cvterm => 'track_type',
                :history_depth => 0
              ).save
              TrackTag.new(
                :experiment_id => experiment_id,
                :name => 'BigWig File',
                :project_id => project_id,
                :track => tracknum,
                :value => File.basename(bigwig_file_path),
                :cvterm => 'bigwig_file',
                :history_depth => 0
              ).save 
              TrackTag.new(
                :experiment_id => experiment_id,
                :name => 'Feature Type',
                :project_id => project_id,
                :track => tracknum,
                :value => row['term'],
                :cvterm => "feature_type",
                :history_depth => 0
              ).save
            }
          }
          cmd_puts "      Done getting wiggle files."

          # TODO: Merge any wiggle tracks that are just one-per-chromosome
#          new_gffs = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = Array.new } }
#          gff_files.each { |gff_file|
#            f = File.new(gff_file);
#            lines = f.readlines
#            f.close
#            if lines.size == 3 then
#              tracknum = gff_file.match(/\/(\d+)_wiggle\.gff/)[1]
#              name = lines.last.match(/\tName=([^;]+)/)[1]
#              new_gffs[name]["tracknums"].push tracknum
#              new_gffs[name]["lines"].push lines.last
#              new_gffs[name]["files"].push gff_file
#              File.unlink(gff_file)
#            end
#          }
#          new_gffs.each_pair { |name, info|
#            # Delete all but one metadata
#            cmd_puts "Merging all chromosomes from tracks #{info["tracknums"].join(", ")} for #{name} into a single track: #{info["tracknums"].first}."
#            first_track_num = info["tracknums"].shift
#            info["tracknums"].each { |tracknum|
#              TrackTag.delete_all "project_id = #{project_id} AND track = #{tracknum}"
#            }
#            # Generate the new GFF
#            tracknum = first_track_num
#            gff_file_path = File.join(output_dir, "#{tracknum}_wiggle.gff")
#            f = File.new(gff_file_path, "w")
#            f.puts "#gff-version 3"
#            f.puts ""
#            info["lines"].each { |line| f.puts line }
#          }
        end
        if data_ids_with_sam_files.size > 0 then
          cmd_puts "      Getting SAM files."
          dbh_safe {
            @sth_get_sam_by_data_ids.execute data_ids_with_sam_files.uniq
            @sth_get_sam_by_data_ids.fetch_hash { |row|
              next if seen_sams.include?(row["sam_file"])
              seen_sams.push(row["sam_file"])
              cmd_puts "        Verifying presence of sorted BAM file."
              bam_file_subdir = ""
              bam_file_path = File.join(ExpandController.path_to_project_dir(Project.find(project_id)), "extracted", row["sorted_bam_file"])
              if (!File.exist?(bam_file_path)) then
                curdir = File.dirname(bam_file_path)
                subdirs = Dir.entries(curdir).reject { |entry| entry =~ /^\./ }.find_all { |entry| File.directory?(File.join(curdir, entry)) }
                cmd_puts "          Recursing into single existing subdirectory."
                bam_file_path = File.join(curdir, subdirs[0], File.basename(bam_file_path)) if subdirs.size == 1
                bam_file_subdir = subdirs[0] if subdirs.size == 1
              end
              if (!File.exist?(bam_file_path)) then
                # Maybe it's in a subdir?
                cmd_puts "          Sorted BAM \"#{row["sorted_bam_file"]}\" NOT FOUND, skipping this SAM file!"
                next
              end
              cmd_puts "          Sorted BAM \"#{row["sorted_bam_file"]}\" found."
              tracks_dir = File.join(ExpandController.path_to_project_dir(Project.find(project_id)), "tracks")

              cmd_puts "          Copying BAM file(s) to tracks dir."
              [ row["sorted_bam_file"], "#{row["sorted_bam_file"]}.bai" ].each { |f|
                tracks_subdir = tracks_dir
                if (tracks_dir != File.dirname(File.join(tracks_dir, f))) then
                  FileUtils.mkdir_p(File.dirname(File.join(tracks_dir, f)))
                  tracks_subdir = File.dirname(File.join(tracks_dir, f))
                end
                src_bam = File.join(ExpandController.path_to_project_dir(Project.find(project_id)), "extracted", bam_file_subdir, f)
                FileUtils.cp(
                  src_bam,
                  File.join(tracks_subdir, File.basename(f))
                )
              }
              cmd_puts "          Done."
              cmd_puts "        Finding metadata for SAM files."
              tracknum = attach_generic_metadata(ap_ids, experiment_id, project_id, protocol_ids_by_column)
              cmd_puts "          Using tracknum #{tracknum}"
              cmd_puts "        Done."

              # Label this as a SAM track
              TrackTag.new(
                :experiment_id => experiment_id,
                :name => 'BAM File',
                :project_id => project_id,
                :track => tracknum,
                :value => File.join(bam_file_subdir, row["sorted_bam_file"]),
                :cvterm => 'bam_file',
                :history_depth => 0
              ).save
              TrackTag.new(
                :experiment_id => experiment_id,
                :name => 'Track Type',
                :project_id => project_id,
                :track => tracknum,
                :value => 'bam',
                :cvterm => 'track_type',
                :history_depth => 0
              ).save
            }
          }
          cmd_puts "      Done getting SAM files."
        end
      end
    end
    unless found_any_tracks then
      # Generate a citation even though we didn't find any tracks
      cmd_puts "    No tracks found for this submission; generating generic metadata for citation."
      ap_ids = usable_tracks.map { |col, set_of_tracks| set_of_tracks.map { |aps| aps.map { |ap| ap.applied_protocol_id } }.flatten }.flatten
      tracknum = attach_generic_metadata(ap_ids, experiment_id, project_id, protocol_ids_by_column)
      cmd_puts "      Using tracknum #{tracknum}"
      TrackTag.new(
        :experiment_id => experiment_id,
        :name => 'Track Type',
        :project_id => project_id,
        :track => tracknum,
        :value => 'placeholder',
        :cvterm => 'track_type',
        :history_depth => 0
      ).save
      cmd_puts "    Done."
    end
    cmd_puts "  Done."
    ####### /Find Features/Wiggles #######

    # Didn't find anything? Still need a citation?
    return true
  end
  def recursive_output(seen_feature_ids, sth_get_gff, gff_file, parent_id = nil)
    if !parent_id.nil? then
      sth_get_gff.execute parent_id
    else
      return unless seen_feature_ids.keys.size > 0
      sth_get_gff.execute seen_feature_ids.shift[0]
    end
    row = sth_get_gff.fetch
    return if row.nil?
    parents = row[1].nil? ? '' : row[1].split(',').map { |parent| parent.split('/') }
    parents.each { |reltype, parent_id|
      if seen_feature_ids[parent_id] then
        seen_feature_ids.delete(parent_id)
        recursive_output(seen_feature_ids, sth_get_gff, gff_file, parent_id)
      end
    }
    text = row[0] + parents.map { |reltype, parent_id| ";Parent=#{parent_id};parental_relationship=#{reltype}/#{parent_id}" }.join
    gff_file.puts text.gsub(/#/, '_')
  end
  def feature_to_gff(feature, tracknum)
    # Format GFF fields for output
    feature['uniquename'] = (feature['uniquename'].gsub(/[;=\[\]\/, ]/, '_'))
    feature['name'] = (feature['name'].gsub(/[;=\[\]\/, ]/, '_')) unless feature['name'].nil?
    feature['strand'] = 0 if feature['strand'].nil?
    case feature['strand'].to_i
    when -1 then feature['strand'] = '-'
    when 1 then feature['strand'] = '+'
    else feature['strand'] = '.'
    end
    feature['phase'] = '.' if feature['phase'].nil?
    feature['fmin'] = '.' if feature['fmin'].nil?
    feature['fmax'] = '.' if feature['fmax'].nil?

    feature['srcfeature'] = feature['feature_id'] if feature['srcfeature'].nil?

    score = feature['score'] ? feature['score'] : "."
    out = "#{feature['srcfeature']}\t#{tracknum}_details\t#{feature['type']}\t#{feature['fmin'] == "." ? "." : (feature['fmin'].to_i+1)}\t#{feature['fmax']}\t#{score}\t#{feature['strand']}\t#{feature['phase']}\tID=#{feature['feature_id']}"

    # Build the attributes column
    if !feature['name'].nil? && feature['name'].length > 0 then
      out = out + ";Name=#{feature['name'][0...128]}"
    elsif !feature['uniquename'].nil? && feature['uniquename'].length > 0 then
      out = out + ";Name=#{feature['uniquename'][0...128]}"
    end
    out = out + ";Target=#{feature['target']}" unless feature['target'].nil?
    out = out + ";target_accession=#{feature['target_accession']}" unless feature['target_accession'].nil?
    out = out + ";analysis=#{feature['analysis']}" unless feature['analysis'].nil?
    out = out + ";normscore=#{feature['normscore']}" unless feature['normscore'].nil?
    out = out + ";identity=#{feature['identity']}" unless feature['identity'].nil?
    out = out + ";significance=#{feature['significance']}" unless feature['significance'].nil?

    # Parental relationships
#    feature["parents"].each do |reltype, parent|
#      # Write the parental relationship
#      out = out + ";Parent=#{parent}"
#      out = out + ";parental_relationship=#{reltype}/#{parent}"
#    end

    # Attributes
    feature["properties"].each do |propname, ranks|
      out = out + ";#{propname.downcase.gsub(/[^A-Za-z0-9]/, "_")}="
      out = out + ranks.sort { |v1, v2| v1[0] <=> v2[0] }.map { |val| val[1].gsub(/[,;]/, "_") }.join(",")
    end

    out
  end
  def load_into_gbrowse(project_id, directory)
    schemas = self.get_experiments
    experiment_id = schemas["modencode_experiment_#{project_id}"][0]
    tags = TrackTag.find_all_by_experiment_id(experiment_id, :select => "DISTINCT(track), null AS cvterm")
    tracknums = tags.map { |t| t.track }.uniq

    gff_files = Hash.new { |hash, key| hash[key] = Array.new }
    Find.find(directory) do |path|
      Find.prune if File.directory?(path) && path != directory # Don't recurse
      if matchdata = File.basename(path).match(/^(\d*)(_.*)?\.gff/) then
        gff_files[matchdata[1]].push path if tracknums.include? matchdata[1].to_i
      end
    end
    schema = "modencode_experiment_#{project_id}_data"
    dbinfo = TrackFinder.gbrowse_database

    schema_ddl = ''
    File.open(File.join(TrackFinder::gbrowse_root, 'ddl/data_schema_with_replaceable_names.sql')) { |ddl_file|
      schema_ddl = ddl_file.read.gsub(/\$temporary_chado_schema_name\$/, schema)
    }
    cmd_puts "Generating new tablespace in GBrowse database."
    # Can't execute multiple statements (e.g. DDL) in Ruby DBI
    gff_schema_loader = IO.popen("perl", "w")
    gff_schema_loader.print LOAD_SCHEMA_TO_GFFDB_PERL + "\n\004\n"
    gff_schema_loader.puts dbinfo[:perl_dsn]
    gff_schema_loader.puts dbinfo[:user]
    gff_schema_loader.puts dbinfo[:password]
    gff_schema_loader.puts "DROP SCHEMA IF EXISTS #{schema} CASCADE;"
    gff_schema_loader.puts(schema_ddl);
    gff_schema_loader.close
    cmd_puts "Done."

    cmd_puts "Loading GFF and Wiggle files into GBrowse database."
    gff_files.map { |k, v| v }.flatten.each do |gff_file|
      cmd_puts "  Loading track #{File.basename(gff_file)}."
      # Load using adapted bp_seqfeature_load
      gff_loader = IO.popen("perl", "w")
      gff_loader.print LOAD_GFF_TO_GFFDB_PERL + "\n\004\n"
      gff_loader.puts gff_file
      gff_loader.puts dbinfo[:adaptor]
      gff_loader.puts dbinfo[:perl_dsn]
      gff_loader.puts dbinfo[:user]
      gff_loader.puts dbinfo[:password]
      gff_loader.puts schema
      gff_loader.close
    end
    cmd_puts "Done."
  end

  @debug = false
  def debug=(d)
    @debug = d
  end


  # Track configuration
  def generate_gbrowse_conf(project_id)
    project = Project.find(project_id)

    dbinfo = TrackFinder.gbrowse_database
    gff_dbh = dbh_safe { DBI.connect(dbinfo[:ruby_dsn], dbinfo[:user], dbinfo[:password]) }

    schema = "modencode_experiment_#{project_id}_data"
    self.search_path = schema
    @sth_get_experiment_id.execute
    experiment_id = @sth_get_experiment_id.fetch_hash["experiment_id"]
    cmd_puts "for project #{project_id} got experiment id #{experiment_id}" if debugging?

    tags = TrackTag.find_all_by_experiment_id(experiment_id, :select => "DISTINCT(track), null AS cvterm")

    tracknums = tags.map { |t| t.track }.uniq

    types = Array.new
    if dbh_safe { gff_dbh.execute("SET search_path = #{schema}") } != false
      sth_get_types = dbh_safe { gff_dbh.prepare("SELECT tag FROM typelist WHERE tag LIKE '%:' || ? OR tag LIKE '%:' || ? || '_details'") }
      tracknums.each do |tracknum|
        sth_get_types.execute(tracknum, tracknum)
        sth_get_types.fetch do |row|
          types.push row[0]
        end
      end
      dbh_safe { sth_get_types.finish }
    end

    type_tags = TrackTag.find_all_by_project_id_and_cvterm_and_name(project_id, "track_type", "Track Type")
    sam_tags = type_tags.find_all { |tt| tt.value == "bam" }
    sam_tags.each do |sam_tag|
      types.push "read_pair:#{sam_tag.track}"
    end

    # Also find bigwig tags -
    # Previously these tracks would have been found via typelist above but that is no longer populated
    bigwig_tags = type_tags.find_all { |tt| tt.value == "feature" }.find_all { |tt| TrackTag.find_by_track_and_cvterm(tt.track, 'bigwig_file') } + type_tags.find_all { |tt| tt.value == "bigwig" }
    bigwig_tags.each do |bigwig_tag|
      bigwig_type_tags = TrackTag.find_all_by_track_and_cvterm(bigwig_tag.track, "feature_type")
      bigwig_type_tags.each { |bigwig_type|
        # bigwig:tracknum:track type:feature type
        types.push "bigwig:#{bigwig_tag.track}:#{bigwig_tag.value}:#{bigwig_type.value}"
      }
    end
    track_defs = Hash.new

    # Handle projects with no tracks (generate placeholder citation)
    if types.size == 0 then
      stanzaname = "metadata_description"
      c = Citation.new(project_id)
      citation_text = c.build
      track_defs[stanzaname] = { 'citation' => citation_text }
      return track_defs
    end


    sth_get_num_located_types = dbh_safe { gff_dbh.prepare("SELECT COUNT(*) FROM locationlist l INNER JOIN feature f ON l.id = f.seqid INNER JOIN typelist tl ON f.typeid = tl.id WHERE tl.tag = ? AND l.seqname = ANY(?)") }


    default_organism = "Drosophila melanogaster"
    types.each do |type|
      puts "Testing type #{type}" if @debug

      track_type = track_source = tracknum = nil;
      if (type !~ /^read_pair/) && (type !~ /^bigwig/ )  then
        # Make sure this feature type is located to a chromosome
        # If it's from bigwig it won't be in the database so let it pass
        sth_get_num_located_types.execute(type, TrackFinder::CHROMOSOMES.values.flatten)
        next unless sth_get_num_located_types.fetch[0] > 0
      end

      matchdata = type.match(/(.*):((\d*)(_details)?)(?::([^:]*))?(?::([^:]*))?$/)
      track_type = matchdata[1]
      track_source = matchdata[2]
      tracknum = matchdata[3]
      bigwig_type = matchdata[5]
      feature_type = matchdata[6] if matchdata[6] # If it's a specified feature type from bigwig
      track_type = "bigwig" if bigwig_type

      key = "#{project.id} #{project.name[0..10]} #{track_type}:#{tracknum}"
      tag_wiggle_file = TrackTag.find_by_experiment_id_and_track_and_cvterm(experiment_id, tracknum.to_i, 'wiggle_file')
      if tag_wiggle_file then
        key = "#{project.id} -#{tag_wiggle_file.value}- #{track_type}:#{tracknum}"
      end
      tag_gff_file = TrackTag.find_by_experiment_id_and_track_and_cvterm(experiment_id, tracknum.to_i, 'gff_file')
      if tag_gff_file then
        key = "#{project.id} -#{tag_gff_file.value}- #{track_type}:#{tracknum}"
      end

      track_id = tracknum
      data_source_id = ([project.id] + (TrackTag.find_all_by_experiment_id_and_track_and_cvterm(experiment_id, tracknum.to_i, 'referenced_submission').map { |tt| tt.value })).join(" ")
      min_score = nil
      max_score = nil
      neg_color = nil
      pos_color = nil
      smoothing = nil
      smoothing_window = nil
      bicolor_pivot = nil
      fgcolor = "black"
      bgcolor = "lightgrey"
      glyph = "generic"
      label = "sub { return shift->name; }"
      label_transcripts = ""
      connector = "solid"
      connector_color = "solid"
      group_on = nil
      draw_target = nil
      show_mismatch = nil
      height = nil
      label_density = 100
      bump = nil
      maxdepth = nil
      bigwig_file = nil
      bam_file = nil
      fasta_file = nil
      database = "modencode_preview_#{project.id}"
      zoomlevels = [ nil ]
      feature = type
      # Get keywords from file and set them all to nil for the moment
      keywords = Hash.new
      if File.exists? "#{RAILS_ROOT}/config/keywords.yml" then
       keywords =  open("#{RAILS_ROOT}/config/keywords.yml"){ |f| YAML.load(f.read) }
      end
            
      case track_type
      when "match" then
        glyph = "box"
        label = 'sub { my @ts = shift->each_tag_value("Target"); foreach my $t (@ts) { $t =~ s/\s+\d+\s+\d+\s*$//g; return $t; } }'
      when "EST_match" then
        glyph = "box"
        label = 'sub { my @ts = shift->each_tag_value("Target"); foreach my $t (@ts) { $t =~ s/\s+\d+\s+\d+\s*$//g; return $t; } }'
      when "match_part" then
        glyph = "segments"
        label = 'sub { my $f = shift; return unless scalar($f->get_SeqFeatures); my @ts = [$f->get_SeqFeatures]->[0]->each_tag_value("Target"); foreach my $t (@ts) { $t =~ s/\s+\d+\s+\d+\s*$//g; return $t; } }'
        group_on = 'sub { my @ts = shift->each_tag_value("Target"); foreach my $t (@ts) { $t =~ s/\s+\d+\s+\d+\s*$//g; return $t; } }'
      when "histone_binding_site" then
        glyph = "segments"
        label = 'sub { my ($type) = (shift->type =~ m/(.*):\d*/); return $type; }'
        connector = "0"
        connector_color = "white"
      when "TF_binding_site" then
        glyph = "segments"
        label = ''
        connector = "0"
        connector_color = "white"
      when "binding_site" then
        glyph = "segments"
        nabel = 'sub { my ($type) = (shift->type =~ m/(.*):\d*/); return $type; }'
        connector_color = "white"
      when "transcript_region" then
        glyph = "segments"
        fgcolor = "lightgrey"
      when "transcript" then
        glyph = "processed_transcript"
      when "intron" then
        glyph = "box"
        label = ''
      when "gene" then
        glyph = "gene"
      when "read_pair" then
        feature = "read_pair"
        glyph = "segments"
        label = "sub { return shift->display_name; }"
        draw_target = "1"
        show_mismatch = "1"
        bgcolor = "blue"
        fgcolor = "blue"
        height = 10
        label_density = 50
        bump = "fast"
        maxdepth = 2
        database = "modencode_bam_#{project.id}_#{tracknum}"
        bam_file = TrackTag.find_by_project_id_and_name_and_cvterm_and_track(project.id, "BAM File", "bam_file", tracknum).value
        zoomlevels = [ nil, 1000 ]
      when "bigwig" then
        track_type = feature_type
        feature = "summary"
        glyph = "wiggle_xyplot"
        height = 10
        bgcolor = "blue"
        database = "modencode_bigwig_#{project.id}_#{tracknum}_#{bigwig_type}"
        puts "FEATURE TYPE SPOSED TO BE #{feature_type}, BIGWIG TYPE IS #{bigwig_type}"
        if bigwig_type == "feature" then
          bigwig_file = TrackTag.find_by_project_id_and_name_and_cvterm_and_track(project.id, "BigWig File #{feature_type}", "bigwig_file", tracknum).value
          puts "GOT BIGWIG A: #{bigwig_file}"
        else
          bigwig_file = TrackTag.find_by_project_id_and_name_and_cvterm_and_track(project.id, "BigWig File", "bigwig_file", tracknum).value
          puts "GOT BIGWIG B: #{bigwig_file}"
        end
      end

      stanzaname = "#{project.name[0..10].gsub(/[^A-Za-z0-9-]/, "_")}_#{track_type.gsub(/[^A-Za-z0-9-]/, '_')}_#{tracknum}_#{project.id}"
      stanzaname.sub!(/^[^A-Za-z]*/, '')

      
      if track_source !~ /\d*_details/ then
        # If this is not a details track...
        if types.find { |other_type| other_type == "#{track_type}:#{tracknum}_details" } then
          # ...but there is a details track for this feature type, then the
          # current track is the wiggle view for features that are 
          # a GFF file when zoomed in
          zoomlevels = [ 100002 ]
          glyph = "wiggle_density"
        end
      end
      
      tag_track_type = TrackTag.find_by_experiment_id_and_track_and_cvterm(experiment_id, tracknum.to_i, 'track_type')
     


      if tag_track_type then
      cmd_puts "got tag_track_type and it's #{tag_track_type.inspect} ok" if debugging?

        if tag_track_type.value == "wiggle" then
          # Wiggle-only
          glyph = "wiggle_xyplot"
          glyph_select = "wiggle_density wiggle_xyplot"
          min_score = -20
          max_score = 20
          neg_color = "orange"
          pos_color = "blue"
          smoothing = "mean"
          smoothing_window = 10
          bicolor_pivot = "zero"
          height = 30
          sort_order = 'sub ($$) {shift->feature->name cmp shift->feature->name}'
        else
          # GFF-only
          unique_analyses = TrackTag.find_all_by_experiment_id_and_track_and_cvterm(experiment_id, tracknum.to_i, 'unique_analysis')
          unique_analyses = unique_analyses.size > 1 ? unique_analyses.map { |tt| tt.value }.uniq : nil
        end
      
        # Get bigwig information if it's a wiggle or feature
#        if tag_track_type.value == "wiggle" || tag_track_type.value == "feature" then
#          puts "finding bigwig with #{project.id}|#{tracknum}ok" if debugging?
#          bigwig_tags = TrackTag.find_by_project_id_and_name_and_cvterm_and_track(project.id, "BigWig File", "bigwig_file", tracknum)
#          bigwig_file = bigwig_tags.value if bigwig_tags
#          puts "found bigwig file #{bigwig_file.inspect}ok" if debugging?
#        end
      end

      c = Citation.new(project_id)
      citation_text = c.build

      tag_track_organism = TrackTag.find_by_experiment_id_and_track_and_cvterm(experiment_id, tracknum.to_i, 'organism')

      track_defs[stanzaname] = Hash.new if track_defs[stanzaname].nil?
      track_defs[stanzaname][:organism] = tag_track_organism.value unless tag_track_organism.nil?
      default_organism = track_defs[stanzaname][:organism] unless track_defs[stanzaname][:organism].nil?
      track_defs[stanzaname][:semantic_zoom] = Hash.new if track_defs[stanzaname][:semantic_zoom].nil?
      
      zoomlevels.each { |zoomlevel|
        if zoomlevel.nil? then
          track_defs[stanzaname]['track_id'] = track_id
          track_defs[stanzaname]['data_source_id'] = data_source_id
          track_defs[stanzaname]['category'] = "Preview"
          track_defs[stanzaname]['feature'] = feature
          track_defs[stanzaname]['fgcolor'] = fgcolor
          track_defs[stanzaname]['bgcolor'] = bgcolor
          track_defs[stanzaname]['stranded'] = 0
          track_defs[stanzaname]['group_on'] = group_on
          track_defs[stanzaname]['label_transcripts'] = label_transcripts
          track_defs[stanzaname]['database'] = database
          track_defs[stanzaname]['key'] = key
          track_defs[stanzaname]['citation'] = citation_text
          track_defs[stanzaname]['label'] = label
          track_defs[stanzaname]['bump density'] = 250
          track_defs[stanzaname]['label density'] = label_density
          track_defs[stanzaname]['glyph'] = glyph
          track_defs[stanzaname]['connector'] = connector
          track_defs[stanzaname][:unique_analyses] = unique_analyses unless unique_analyses.nil?

          # Make a new hash for the keywords - don't fill in any yet
          track_defs[stanzaname]['keywords']={}
          keywords.each{ | key, value |
            track_defs[stanzaname]['keywords'][key] = nil }

          # Wiggle-only stuff
          track_defs[stanzaname]['min_score'] = min_score unless min_score.nil?
          track_defs[stanzaname]['max_score'] = max_score unless max_score.nil?
          track_defs[stanzaname]['neg_color'] = neg_color unless neg_color.nil?
          track_defs[stanzaname]['pos_color'] = pos_color unless pos_color.nil?
          track_defs[stanzaname]['smoothing'] = smoothing unless smoothing.nil?
          track_defs[stanzaname]['smoothing_window'] = smoothing_window unless smoothing_window.nil?
          track_defs[stanzaname]['bicolor_pivot'] = bicolor_pivot unless bicolor_pivot.nil?
          track_defs[stanzaname]['glyph select'] = glyph_select  unless glyph_select .nil?
          track_defs[stanzaname]['sort_order'] = sort_order unless sort_order.nil?

          # Bigwig stuff
          track_defs[stanzaname][:bigwig_file] = bigwig_file unless bigwig_file.nil? 
          track_defs[stanzaname]['bigwig_file_path'] = File.basename(bigwig_file) unless bigwig_file.nil?

          # SAM-only stuff
          track_defs[stanzaname]['draw_target'] = draw_target unless draw_target.nil?
          track_defs[stanzaname]['show_mismatch'] = show_mismatch unless show_mismatch.nil?
          track_defs[stanzaname]['height'] = height unless height.nil?
          track_defs[stanzaname]['bump'] = bump unless bump.nil?
          track_defs[stanzaname]['maxdepth'] = maxdepth unless maxdepth.nil?
          track_defs[stanzaname][:bam_file] = bam_file unless bam_file.nil?
          track_defs[stanzaname]['bam_file_path'] = File.basename(bam_file) unless bam_file.nil?
        else
          track_defs[stanzaname][:semantic_zoom][zoomlevel] = Hash.new
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['feature'] = type
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['height'] = 30
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['label'] = label
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['glyph'] = glyph
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['fgcolor'] = fgcolor
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['bgcolor'] = bgcolor
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['stranded'] = 0
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['group_on'] = group_on
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['min_score'] = min_score unless min_score.nil?
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['max_score'] = max_score unless max_score.nil?
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['neg_color'] = neg_color unless neg_color.nil?
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['pos_color'] = pos_color unless pos_color.nil?
          
          # Bigwig stuff
          track_defs[stanzaname][:semantic_zoom][zoomlevel][:bigwig_file] =  bigwig_file.nil? ? "semantic zoom nil bigwig" : bigwig_file
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['bigwig_file_path'] = File.basename(bigwig_file) unless bigwig_file.nil?

          if type =~ /read_pair:/ then
            # Special case for zoomed-out SAM
            track_defs[stanzaname][:semantic_zoom][zoomlevel]['feature'] = "coverage"
            track_defs[stanzaname][:semantic_zoom][zoomlevel]['glyph'] = "wiggle_xyplot"
          end
          if type =~ /bigwig:/ then
            # Special case for zoomed-out SAM
            track_defs[stanzaname][:semantic_zoom][zoomlevel]['feature'] = "summary"
            track_defs[stanzaname][:semantic_zoom][zoomlevel]['glyph'] = "wiggle_density"
            track_defs[stanzaname][:semantic_zoom][zoomlevel]['database'] = database
          end
        end
      }
    end

    track_defs.each do |stanzaname, config|
      config[:organism] = default_organism if config[:organism].nil?
    end

    return track_defs
  end
end
