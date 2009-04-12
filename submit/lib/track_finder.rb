require 'applied_protocol'
require 'rubygems'
require 'dbi'
require 'cgi'
require 'pg_database_patch'
require 'find'

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
  DEBUG = false
  TRACKS_PER_COLUMN = 5
  MAX_FEATURES_PER_CHR = 10000
  CHROMOSOMES = [ 
              '2L', '2LHet', '2R', '2RHet', '3L', '3LHet', '3R', '3RHet', '4', 'X', 'XHet', 'YHet', 'U', 'Uextra', 'M',
              'I', 'II', 'III', 'IV', 'V', 'X', 'MtDNA'
  ]

  # GBrowse configuration
  def self.gbrowse_root
    if File.exists? "#{RAILS_ROOT}/config/gbrowse.yml" then
      gbrowse_config = open("#{RAILS_ROOT}/config/gbrowse.yml") { |f| YAML.load(f.read) }
      return gbrowse_config['root_dir'];
    else
      raise Exception("You need a gbrowse.yml file in your config/ directory with at least a root_dir in it.")
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
      raise Exception("You need an gbrowse_database.yml file in your config/ directory with at least an adaptor and dsn.")
    end
  end
  def self.gbrowse_tmp
    if File.exists? "#{RAILS_ROOT}/config/gbrowse.yml" then
      gbrowse_config = open("#{RAILS_ROOT}/config/gbrowse.yml") { |f| YAML.load(f.read) }
      return gbrowse_config['tmp_dir'];
    else
      raise Exception("You need a gbrowse.yml file in your config/ directory with at least a tmp_dir in it.")
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
  WIGGLE_TO_WIGDB_PERL = <<-EOP
  package Bio::Graphics::Wiggle::ModENCODELoader;
  use strict;
  use lib '#{TrackFinder.gbrowse_lib}';
  use Bio::Graphics::Wiggle;
  use Bio::Graphics::Wiggle::Loader;
  use base qw(Bio::Graphics::Wiggle::Loader);
  use Carp qw(croak);

  sub new {
    my $class = shift;
    my $base = shift;
    return bless {
      base => $base,
      tracks => {},
      track_options => {},
    }, ref($class) || $class;
  }

  sub wigfile {
    my $self = shift;
    my $seqid = shift;
    my $current_track = $self->{tracknum};
    my $tname          = $self->{trackname};
    unless (exists $self->current_track->{seqids}{$seqid}{wig}) {
      my $path = sprintf($self->{base}, $seqid);
      my @stats;
      foreach (qw(min max mean stdev)) {
          my $value = $self->current_track->{seqids}{$seqid}{$_} ||
              $self->{FILEWIDE_STATS}{$_} || next;
          push @stats,($_=>$value);
     }

      my $step = $self->{track_options}{step} || 1;
      my $span = $self->{track_options}{span} || $self->{track_options}{step} || 1;

      my $trim      = $self->current_track->{display_options}{trim};# || 'stdev2';
      my $transform = $self->current_track->{display_options}{transform};
      my $wigfile = Bio::Graphics::Wiggle->new(
                                               $path,
                                               1,
                                               {
                                                seqid => $seqid,
                                                step  => $step,
                                                span  => $span,
                                                trim  => $trim,
                                                @stats,
                                               },
                                              );
      $wigfile or croak "Couldn't create wigfile $wigfile: $!";

      $self->current_track->{seqids}{$seqid}{wig}     = $wigfile;
      $self->current_track->{seqids}{$seqid}{wigpath} = $path;
    }
    return $self->current_track->{seqids}{$seqid}{wig};
  }
  1;

  package main;
  use File::Basename;
  use strict;

  my $wig_db_file_template = <>;
  my $gff_file_path = <>;
  my $gff_type = <>;
  my $source = <>;
  my $filename = <>;
  chomp $wig_db_file_template; chomp $gff_file_path; chomp $gff_type; chomp $source; chomp $filename;

  my $loader = Bio::Graphics::Wiggle::ModENCODELoader->new($wig_db_file_template) or die "Could not create loader";
  my $fh = IO::File->new($filename) or die "Couldn't open $filename: $!";
  $loader->load($fh);

  # Write out the GFF
  open GFF, ">$gff_file_path";
  my $line = $loader->featurefile('gff3', $gff_type, $source);
  my $tmppath = dirname($wig_db_file_template);
  my $realpath = dirname($gff_file_path);
  $line =~ s/\\Q$tmppath\\E/$realpath/g;
  print GFF $line;
  close GFF;

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
      raise Exception("You need an idf2chadoxml_database.yml file in your config/ directory with at least a Ruby DBI dsn.")
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
      (sth_get_num_feature_relationships.fetch[0] > 0) ? true : false
    }
  end
  def dbh_safe
    if block_given? then
      begin
        return yield
      rescue DBI::DatabaseError => e
        cmd_puts "DBI error: #{e.err} #{e.errstr}"
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

    # Track finding queries:
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
                   HAVING count(wig.*) > 0 OR COUNT(df.*) > 0") 
    }
    @sth_get_features_by_data_ids = dbh_safe {
      @dbh.prepare("SELECT
                   d.heading || ' [' || CASE WHEN d.name IS NULL THEN '' ELSE d.name END || ']' AS data_name,
                   f.feature_id,
                   f.name, f.uniquename,
                   cvt.name AS type,
                   fp.value AS propvalue, fp.rank AS proprank, fptype.name AS propname,
                   fl.fmin, fl.fmax, fl.strand, fl.phase, fl.rank, fl.residue_info,
                   src.name AS srcfeature,
                   src.uniquename AS srcfeature_accession,
                   src.feature_id AS srcfeature_id,
                   srctype.name AS srctype,
                   o.genus, o.species,
                   af.rawscore AS score, af.normscore AS normscore, af.significance AS significance, af.identity AS identity,
                   a.program AS analysis
                   FROM data_feature df
                   INNER JOIN feature f ON f.feature_id = df.feature_id
                   INNER JOIN organism o ON f.organism_id = o.organism_id
                   INNER JOIN cvterm cvt ON f.type_id = cvt.cvterm_id
                   INNER JOIN data d ON df.data_id = d.data_id
                   LEFT JOIN (featureprop fp
                     INNER JOIN cvterm fptype ON fp.type_id = fptype.cvterm_id
                   ) ON fp.feature_id = f.feature_id
                   LEFT JOIN (featureloc fl 
                     LEFT JOIN (feature src
                       INNER JOIN cvterm srctype ON src.type_id = srctype.cvterm_id
                     ) ON src.feature_id = fl.srcfeature_id
                   ) ON df.feature_id = fl.feature_id
                   LEFT JOIN (analysisfeature af
                     INNER JOIN analysis a ON af.analysis_id = a.analysis_id
                   ) ON f.feature_id = af.feature_id
                   WHERE df.data_id = ANY(?) ORDER BY f.feature_id, fl.rank")
    }
    @sth_get_parts_of_features = dbh_safe {
      @dbh.prepare("SELECT
                   fr.object_id AS parent_id,
                   f.feature_id,
                   f.name, f.uniquename,
                   cvt.name AS type,
                   fp.value AS propvalue, fp.rank AS proprank, fptype.name AS propname,
                   fl.fmin, fl.fmax, fl.strand, fl.phase, fl.rank, fl.residue_info,
                   src.name AS srcfeature,
                   src.uniquename AS srcfeature_accession,
                   src.feature_id AS srcfeature_id,
                   srctype.name AS srctype,
                   frtype.name AS relationship_type,
                   af.rawscore AS score, af.normscore AS normscore, af.significance AS significance, af.identity AS identity,
                   a.program AS analysis
                   FROM feature f
                   INNER JOIN cvterm cvt ON f.type_id = cvt.cvterm_id
                   INNER JOIN feature_relationship fr ON fr.subject_id = f.feature_id
                   INNER JOIN cvterm frtype ON fr.type_id = frtype.cvterm_id
                   LEFT JOIN (featureprop fp
                     INNER JOIN cvterm fptype ON fp.type_id = fptype.cvterm_id
                   ) ON fp.feature_id = f.feature_id
                   LEFT JOIN (featureloc fl 
                     LEFT JOIN (feature src
                       INNER JOIN cvterm srctype ON src.type_id = srctype.cvterm_id
                     ) ON src.feature_id = fl.srcfeature_id
                   ) ON f.feature_id = fl.feature_id
                   LEFT JOIN (analysisfeature af
                     INNER JOIN analysis a ON af.analysis_id = a.analysis_id
                   ) ON f.feature_id = af.feature_id
                   WHERE fr.object_id = ANY(?) ORDER BY f.feature_id, fl.rank")
    }
    @sth_get_wiggles_by_data_ids = dbh_safe {
      @dbh.prepare("SELECT 
                   d.heading || ' [' || CASE WHEN d.name IS NULL THEN '' ELSE d.name END || ']' AS data_name,
                   wiggle_data.name, 
                   wiggle_data.wiggle_data_id,
                   wiggle_data.data AS wiggle_file,
                   cv.name AS cvname,
                   cvt.name AS term
                   FROM wiggle_data
                   INNER JOIN data_wiggle_data dwd ON wiggle_data.wiggle_data_id = dwd.wiggle_data_id 
                   INNER JOIN data d ON dwd.data_id = d.data_id
                   LEFT JOIN ( 
                     cvterm cvt INNER JOIN cv ON cvt.cv_id = cv.cv_id
                   ) ON cvt.cvterm_id = d.type_id
                   WHERE dwd.data_id = ANY(?)") 
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
  end
  def cmd_puts(message)
    puts message + "\n" if DEBUG
    return if @command_object.nil?
    @command_object.stdout = @command_object.stdout + message + "\n";
    @command_object.save
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
        applied_protocols[row[0]].protocol = row[2]
        applied_protocols[row[0]].protocol_id = row[3]
      end
      sth_aps.finish
    }

    # Then follow the applied_protocol->datum->applied_protocol link
    column = 0
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
        applied_protocols.values.find_all { |ap| ap.column == column }.map { |ap| ap.applied_protocol_id }.uniq.each do |applied_protocol_id|
          sth_aps.execute(applied_protocol_id)
          sth_aps.fetch do |row|
            applied_protocols[row[0]].column = column + 1 # Note that the AP gets autocreated by the hash init block
            applied_protocols[row[0]].inputs.push row[1]
            applied_protocols[row[0]].protocol = row[2]
            applied_protocols[row[0]].protocol_id = row[3]
          end
        end
        column = column + 1
      end
      sth_aps.finish
    }
    cmd_puts "    Done."

    # Currently, each set of inputs or outputs for an applied protocol is a potential track
    # tracks = applied_protocols.values.map { |ap| ap.inputs } + applied_protocols.values.map { |ap| ap.outputs }

    cmd_puts "    Collapsing applied protocols to reduce duplicate tracks."
    # Figure out if the inputs of applied_protocols in a particular column differ
    tracks_per_column = Hash.new
    (0...column).each do |col|
      tracks_per_column[col] = applied_protocols.values.find_all { |ap| ap.column == col }.map { |ap| ap.inputs.sort }.uniq.size
    end

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
        cmd_puts "      #{cur_aps[0].protocol} has #{number_of_tracks} potential distinct tracks; attempting to combine applied protocols."

        # Get all the inputs for tracks that collapse
        inputs_that_collapse = tracks_by_input.reject { |k, v| number_of_tracks/v.size > TRACKS_PER_COLUMN }
        full_collapse_inputs = inputs_that_collapse.reject { |k, v| number_of_tracks != v.size }
        full_collapse_inputs.each do |data_id, aps|
          cmd_puts "        Could collapse all applied protocols for protocol '#{aps[0].protocol}' into one set of track(s) by shared '#{data_names[data_id]}'"
        end

        partial_collapse_inputs = Hash.new { |hash, key| hash[key] = Array.new }
        inputs_that_collapse.reject { |data_id, aps| number_of_tracks == aps.size }.each { |data_id, aps|
          partial_collapse_inputs[data_names[data_id]].push aps
        }

        # TODO: If could do a partial collapse on an anonymous datum, then work back up the protocol chain
        # and find out where the difference _does_ occur
        partial_collapse_inputs.each do |data_name, aps|
          cmd_puts "        Could collapse all applied protocols for protocol '#{aps[0][0].protocol}' into #{aps.size} tracks by shared '#{data_name}'"
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
          cmd_puts "      Creating 1 set(s) of track(s) for protocol '#{cur_aps[0].protocol}'; there is no way to collapse by input."
          usable_tracks[column].push cur_aps
        end
      else
        cmd_puts "      Creating #{number_of_tracks} set(s) of track(s) for protocol '#{cur_aps[0].protocol}'"
        usable_tracks[column].push cur_aps
      end
    end
    dbh_safe { sth_data_names.finish }

    cmd_puts "\n      " + (usable_tracks.sort_by { |col, set_of_tracks| col }.map { |col, set_of_tracks| "Protocol #{col} has #{set_of_tracks.size} set(s) of potential track(s)" }.join(", "))
    cmd_puts "    Done."
    return usable_tracks
  end
  def attach_generic_metadata(ap_ids, experiment_id, project_id, protocol_ids_by_column)
    tracknum = self.get_next_tracknum
    history_depth = 0
    while ap_ids.size > 0
      prev_ap_ids = Array.new
      dbh_safe {
        seen = Array.new
        @sth_metadata.execute(ap_ids)
        @sth_metadata.fetch do |row|
            unless row['data_value'].nil? || row['data_value'].empty? || seen.member?(row['data_value']) then
              # Datum name
              begin
                TrackTag.new(
                  :experiment_id => experiment_id,
                  :name => row['data_value'],
                  :project_id => project_id,
                  :track => tracknum,
                  :value => row['data_value'],
                  :cvterm => row['data_type'],
                  :history_depth => history_depth
                ).save
              rescue
              end
              # Datum URL prefix (for wiki links)
              begin
                TrackTag.new(
                  :experiment_id => experiment_id,
                  :name => row['data_value'],
                  :project_id => project_id,
                  :track => tracknum,
                  :value => row['db_url'],
                  :cvterm => 'data_url',
                  :history_depth => history_depth
                ).save unless row['db_type'] != "URL_mediawiki_expansion"
                seen.push row['data_value']
              rescue
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
            # And go through any attached previous applied protocols
            prev_ap_ids.push row['prev_applied_protocol_id'] unless row['prev_applied_protocol_id'].nil?
        end
      }
      ap_ids = prev_ap_ids.uniq
      history_depth = history_depth + 1
    end

    ### Citation stuff ###
    # Experiment properties
    dbh_safe {
      sth_idf_info = @dbh.prepare "SELECT ep.name, ep.value, ep.rank, c.name AS type FROM experiment_prop ep 
                                   INNER JOIN cvterm c ON ep.type_id = c.cvterm_id 
                                   WHERE experiment_id = ?
                                   GROUP BY ep.name, ep.value, ep.rank, c.name"
      sth_idf_info.execute(experiment_id)
      sth_idf_info.fetch do |row|
        begin
          TrackTag.new(
            :experiment_id => experiment_id,
            :name => row['name'],
            :project_id => project_id,
            :track => tracknum,
            :value => row['value'],
            :cvterm => row['type'],
            :history_depth => row['rank']
          ).save
        rescue
        end
      end
    }

    # Protocol types and names and links
    dbh_safe {
      sth_protocol_type = @dbh.prepare "SELECT p.protocol_id, p.name, a.value AS type, dbx.accession AS url FROM attribute a 
              INNER JOIN protocol_attribute pa ON a.attribute_id = pa.attribute_id 
              INNER JOIN protocol p ON pa.protocol_id = p.protocol_id 
              LEFT JOIN dbxref dbx ON p.dbxref_id = dbx.dbxref_id
              WHERE a.heading = 'Protocol Type' AND p.protocol_id = ?
              GROUP BY p.protocol_id, p.name, type, url"

      protocol_ids_by_column.to_a.sort { |p1, p2| p1[0] <=> p2[0] }.each do |col, protocol_id|
        sth_protocol_type.execute(protocol_id)
        sth_protocol_type.fetch do |row|
          begin
          TrackTag.new(
            :experiment_id => experiment_id,
            :name => row['name'],
            :project_id => project_id,
            :track => tracknum,
            :value => row['type'],
            :cvterm => 'protocol_type',
            :history_depth => col
          ).save
          rescue
          end
          begin
          TrackTag.new(
            :experiment_id => experiment_id,
            :name => row['name'],
            :project_id => project_id,
            :track => tracknum,
            :value => row['url'],
            :cvterm => 'protocol_url',
            :history_depth => col
          ).save
          rescue
          end
        end
      end
    }

    return tracknum
  end
  def generate_track_files_and_tags(experiment_id, project_id, output_dir)
    cmd_puts "Loading feature and wiggle data into GBrowse database..."

    ########## Get Usable Tracks #########
    cmd_puts "  Detecting tracks included in submission."

    # Get datum objects attached to features or wiggle data
    usable_tracks = find_usable_tracks(experiment_id, project_id)
    # Figure out the protocol order
    protocol_ids_by_column = Hash.new
    usable_tracks.each { |col, set_of_tracks| 
      # FIXME: Only supports a single protocol per column
      protocol_ids_by_column[col] = set_of_tracks.first.first.protocol_id
    }

    tracknum_to_data_name = Hash.new

    cmd_puts "  Done."
    ######### /Get Usable Tracks #########
    ######## Find Features/Wiggles #######

    seen_wiggles = Array.new

    cmd_puts "  Finding features and wiggle files attached to tracks."
    usable_tracks.each do |col, set_of_tracks|
      cmd_puts "    For the protocol in column #{col}:"
      set_of_tracks.each do |applied_protocols|
        # Get the data objects for the applied protocol
        ap_ids = applied_protocols.map { |ap| ap.applied_protocol_id }

        data_ids_with_features = Array.new
        data_ids_with_wiggles = Array.new

        dbh_safe {
          @sth_get_data_by_applied_protocols.execute(ap_ids)
          @sth_get_data_by_applied_protocols.fetch_hash do |row|
            if row['number_of_features'].to_i > 0 then
              data_ids_with_features.push row["data_id"].to_i
            elsif row['number_of_wiggles'].to_i > 0 then
              data_ids_with_wiggles.push row["data_id"].to_i
            end
          end
        }

        # No need to continue if there isn't anything to make tracks of
        next unless data_ids_with_features.size > 0 || data_ids_with_wiggles.size > 0

        if data_ids_with_features.size > 0 then
          # Get any features associated with this track's data objects
          cmd_puts "      Getting features."
          cmd_puts "        Finding metadata for features."
          tracknum = attach_generic_metadata(ap_ids, experiment_id, project_id, protocol_ids_by_column)
          cmd_puts "          Using tracknum #{tracknum}"
          cmd_puts "        Done."


          analyses = Array.new
          organisms = Array.new
          features_processed = 0 # Track number of features to determine if we want a wiggle file

          # Open GFF file for writing
          Dir.mkdir(output_dir) unless File.directory? output_dir
          gff_sqlite = DBI.connect("dbi:SQLite3:#{File.join(TrackFinder::gbrowse_tmp, "#{tracknum}_tracks.sqlite")}")
          gff_sqlite.do("CREATE TABLE gff (id INTEGER PRIMARY KEY, feature_id INTEGER UNIQUE, gff_string TEXT, parents TEXT, srcfeature VARCHAR(255), type VARCHAR(255), fmin INTEGER, fmax INTEGER)")
          sth_add_gff_parents = gff_sqlite.prepare("UPDATE gff SET parents = parents || ? WHERE feature_id = ?")
          sth_add_gff = gff_sqlite.prepare("INSERT INTO gff (feature_id, gff_string, parents, srcfeature, type, fmin, fmax) VALUES(?, ?, ?, ?, ?, ?, ?)")
          sth_get_gff = gff_sqlite.prepare("SELECT gff_string, parents FROM gff WHERE feature_id = ?")
          sth_get_all_gff = gff_sqlite.prepare("SELECT srcfeature, type, fmin, fmax FROM gff")

          cmd_puts "        Getting top-level features."
          seen_feature_ids = Array.new
          parent_feature_ids = Array.new
          current_feature_hash = Hash.new
          chromosome_located_features = false
          parsed_features = 0
          dbh_safe {
            @sth_get_features_by_data_ids.execute data_ids_with_features.uniq
            @sth_get_features_by_data_ids.fetch_hash { |row|
              next if row['fmin'].nil? || row['fmax'].nil? # Skip features with no location

              if current_feature_hash['feature_id'] != row['feature_id'] then
                unless current_feature_hash['feature_id'].nil? then
                  parsed_features += 1
                  cmd_puts "          Parsed #{parsed_features} features." if parsed_features % 2000 == 0
                  # Write out the current feature
                  sth_add_gff.execute(
                    current_feature_hash['feature_id'], 
                    feature_to_gff(current_feature_hash.dup, tracknum), 
                    '',
                    current_feature_hash['srcfeature'],
                    current_feature_hash['type'],
                    current_feature_hash['fmin'],
                    current_feature_hash['fmax']
                  )
                  seen_feature_ids.push(current_feature_hash['feature_id'])
                  # Metadata
                  chromosome_located_features = true if !current_feature_hash['srcfeature_id'].nil? && current_feature_hash['srcfeature_id'] != current_feature_hash['feature_id']
                  analyses.push current_feature_hash['analysis'] unless current_feature_hash['analysis'].nil?
                  organisms.push current_feature_hash['genus'] + " " + current_feature_hash['species'] unless current_feature_hash['genus'].nil?
                  begin
                    TrackTag.new(
                      :experiment_id => experiment_id,
                      :name => 'Feature',
                      :project_id => project_id,
                      :track => tracknum,
                      :value => current_feature_hash['name'],
                      :cvterm => current_feature_hash['type'],
                      :history_depth => 0
                    ).save
                  rescue
                  end
                end

                # Reinitialize with the new row
                current_feature_hash = row
                current_feature_hash = current_feature_hash.reject { |column, value| col == 'propvalue' || col == 'propname' || col == 'proprank' || col == 'residue_info' }
                current_feature_hash['properties'] = Hash.new { |props, prop| props[prop] = Hash.new }
                current_feature_hash['parents'] = Array.new # Top level features have no parents
                tracknum_to_data_name[tracknum] = current_feature_hash.delete('data_name')
                parent_feature_ids.push row['feature_id']
              else
                # We're still looking at rows for the same feature
                if current_feature_hash['fmin'] != row['fmin'] || current_feature_hash['fmax'] != row['fmax'] || current_feature_hash['srcfeature'] != row['srcfeature'] then
                  if row['rank'].to_i then
                    # The new row is the Target
                    current_feature_hash['target'] = "#{row['srcfeature']} #{row['fmin']} #{row['fmax']}"
                    current_feature_hash['target_accession'] = "#{row['srcfeature_accession']}"
                    current_feature_hash['gap'] = row['residue_info'] if row['residue_info']
                  elsif row['rank'].to_i == 0 then
                    # The previously seen row is the Target; this shouldn't happen because of
                    # an ORDER BY clause in the query, but just to be safe, swap the location entries
                    current_feature_hash['target'] = "#{current_feature_hash['srcfeature']} #{current_feature_hash['fmin']} #{current_feature_hash['fmax']}"
                    current_feature_hash['target_accession'] = "#{current_feature_hash['srcfeature_accession']}"
                    current_feature_hash['fmin'] = row['fmin']
                    current_feature_hash['fmax'] = row['fmax']
                    current_feature_hash['srcfeature'] = row['srcfeature']
                  end
                end
              end

              # Merge all featureprops for a single feature into one object
              current_feature_hash['properties'][row['propname']][row['proprank'].to_i] = row['propvalue'] unless row['propvalue'].nil?
            }

            # Make sure we actually wrote out the last feature
            unless seen_feature_ids.include?(current_feature_hash['feature_id']) then
              # We haven't yet written out current_feature_hash['feature_id']
              unless current_feature_hash['feature_id'].nil? then
                parsed_features += 1
                cmd_puts "          Parsed #{parsed_features} features." if parsed_features % 2000 == 0
                # Write out the current feature
                sth_add_gff.execute(
                  current_feature_hash['feature_id'], 
                  feature_to_gff(current_feature_hash.dup, tracknum), 
                  '',
                  current_feature_hash['srcfeature'],
                  current_feature_hash['type'],
                  current_feature_hash['fmin'],
                  current_feature_hash['fmax']
                )
                seen_feature_ids.push(current_feature_hash['feature_id'])
                # Metadata
                chromosome_located_features = true if !current_feature_hash['srcfeature_id'].nil? && current_feature_hash['srcfeature_id'] != current_feature_hash['feature_id']
                analyses.push current_feature_hash['analysis'] unless current_feature_hash['analysis'].nil?
                organisms.push current_feature_hash['genus'] + " " + current_feature_hash['species'] unless current_feature_hash['genus'].nil?
                begin
                  TrackTag.new(
                    :experiment_id => experiment_id,
                    :name => 'Feature',
                    :project_id => project_id,
                    :track => tracknum,
                    :value => current_feature_hash['name'],
                    :cvterm => current_feature_hash['type'],
                    :history_depth => 0
                  ).save
                rescue
                end
              end
            end
          }
          cmd_puts "        Done fetching top-level features."

          # Child features
          current_feature_hash = Hash.new
          parsed_features = 0
          if there_are_feature_relationships? && parent_feature_ids.size > 0 then
            cmd_puts "        Getting child features."
            dbh_safe {
              @sth_get_parts_of_features.execute parent_feature_ids.uniq
              parent_feature_ids = Array.new
              @sth_get_parts_of_features.fetch_hash { |row|
                if current_feature_hash['feature_id'] != row['feature_id'] then
                  unless current_feature_hash['feature_id'].nil? then
                    current_feature_hash['parents'].uniq!
                    # Write out the current feature
                    if seen_feature_ids.member?(current_feature_hash['feature_id']) then
                      sth_add_gff_parents.execute(
                        current_feature_hash['parents'].map { |reltype, parent| "#{reltype}/#{parent}" }.join(',') + ',',
                        current_feature_hash['feature_id']
                      )
                    else
                      parsed_features += 1
                      cmd_puts "          Parsed #{parsed_features} features." if parsed_features % 2000 == 0
                      seen_feature_ids.push(current_feature_hash['feature_id'])
                      sth_add_gff.execute(
                        current_feature_hash['feature_id'], 
                        feature_to_gff(current_feature_hash.dup, tracknum), 
                        current_feature_hash['parents'].map { |reltype, parent| "#{reltype}/#{parent}" }.join(',') + ',',
                        current_feature_hash['srcfeature'],
                        current_feature_hash['type'],
                        current_feature_hash['fmin'],
                        current_feature_hash['fmax']
                      )
                    end
                    # Metadata
                    chromosome_located_features = true if !current_feature_hash['srcfeature_id'].nil? && current_feature_hash['srcfeature_id'] != current_feature_hash['feature_id']
                    analyses.push current_feature_hash['analysis'] unless current_feature_hash['analysis'].nil?
                    organisms.push current_feature_hash['genus'] + " " + current_feature_hash['species'] unless current_feature_hash['genus'].nil?
                    begin
                      TrackTag.new(
                        :experiment_id => experiment_id,
                        :name => 'Feature',
                        :project_id => project_id,
                        :track => tracknum,
                        :value => current_feature_hash['name'],
                        :cvterm => current_feature_hash['type'],
                        :history_depth => 0
                      ).save
                    rescue
                    end
                  end

                  # Reinitialize with the new row
                  current_feature_hash = row
                  current_feature_hash = current_feature_hash.reject { |column, value| col == 'propvalue' || col == 'propname' || col == 'proprank' || col == 'residue_info' || col == 'object_id' }
                  current_feature_hash['properties'] = Hash.new { |props, prop| props[prop] = Hash.new }
                  current_feature_hash['parents'] = Array.new # To be filled in
                  parent_feature_ids.push row['feature_id']

                  # Add parent relationship
                  current_feature_hash['parents'].push [row['relationship_type'], row['parent_id']] if row['parent_id']
                else
                  # We're still looking at rows for the same feature
                  if current_feature_hash['fmin'] != row['fmin'] || current_feature_hash['fmax'] != row['fmax'] || current_feature_hash['srcfeature'] != row['srcfeature'] then
                    if row['rank'].to_i then
                      # The new row is the Target
                      current_feature_hash['target'] = "#{row['srcfeature']} #{row['fmin']} #{row['fmax']}"
                      current_feature_hash['target_accession'] = "#{row['srcfeature_accession']}"
                      current_feature_hash['gap'] = row['residue_info'] if row['residue_info']
                    elsif row['rank'].to_i == 0 then
                      # The previously seen row is the Target; this shouldn't happen because of
                      # an ORDER BY clause in the query, but just to be safe, swap the location entries
                      current_feature_hash['target'] = "#{current_feature_hash['srcfeature']} #{current_feature_hash['fmin']} #{current_feature_hash['fmax']}"
                      current_feature_hash['target_accession'] = "#{current_feature_hash['srcfeature_accession']}"
                      current_feature_hash['fmin'] = row['fmin']
                      current_feature_hash['fmax'] = row['fmax']
                      current_feature_hash['srcfeature'] = row['srcfeature']
                    end
                  end
                  # Add any new parental relationships
                  current_feature_hash['parents'].push [row['relationship_type'], row['parent_id']] if row['parent_id']
                end

                # Merge all featureprops for a single feature into one object
                current_feature_hash['properties'][row['propname']][row['proprank'].to_i] = row['propvalue'] unless row['propvalue'].nil?
              }
            }
            cmd_puts "        Done getting child features."
          end

          # Track the unique analyses used in this track so we can
          # color by them in the configure_tracks page
          analyses.uniq.each { |analysis|
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
          organisms.uniq.each { |organism|
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

            # Generate a wiggle file
            cmd_puts "        Generating a wiggle file for zoomed-out views."
            sth_get_all_gff.execute
            wiggle_writers = Hash.new { |hash, chromosome| 
              hash[chromosome] = Hash.new { |chrhash, type|
                wiggle_db_file_path = File.join(output_dir, "#{tracknum}_#{chromosome}_#{type}.wigdb")
                wiggle_writer = IO.popen("perl", "w")
                wiggle_writer.puts GFF_TO_WIGDB_PERL + "\n\n"
                wiggle_writer.puts wiggle_db_file_path
                wiggle_writer.puts chromosome
                wiggle_writer.puts "0 255"
                chrhash[type] = { :fmin => nil, :fmax => nil, :writer => wiggle_writer, :path => wiggle_db_file_path }
              }
            }
            sth_get_all_gff.fetch_hash { |row|
              if row['fmin'] && row['fmax'] && CHROMOSOMES.include?(row['srcfeature']) then
                wiggle_writer = wiggle_writers[row['srcfeature']][row['type']]
                wiggle_writer[:writer].puts "#{(row['fmin'].to_i+1).to_s} #{row['fmax']} 255"
                wiggle_writer[:fmin] = [ row['fmin'].to_i, row['fmax'].to_i, wiggle_writer[:fmin].to_i ].reject { |a| a <= 0 }.min
                wiggle_writer[:fmax] = [ row['fmax'].to_i, row['fmax'].to_i, wiggle_writer[:fmax].to_i ].reject { |a| a <= 0 }.max
              end
            }

            # Generate GFF file that refers to wigdb files
            gff_file = File.new(File.join(output_dir, "#{tracknum}_wiggle.gff"), "w")
            gff_file.puts "##gff-version 3"
            wiggle_writers.each { |chromosome, types|
              types.each { |type, writer|
                writer[:writer].close
                track_name = type + " features from " +  tracknum_to_data_name[tracknum]
                gff_file.puts "#{chromosome}\t#{tracknum}\t#{type}\t#{writer[:fmin]}\t#{writer[:fmax]}\t.\t.\t.\tName=#{track_name};wigfile=#{writer[:path]}"
              }
            }
            cmd_puts "        Done."
            cmd_puts "      Done."
            gff_file.close
          end

          sth_get_gff.finish
          sth_get_all_gff.finish
          sth_add_gff_parents.finish
          sth_add_gff.finish
          gff_sqlite.disconnect
          File.unlink(File.join(TrackFinder::gbrowse_tmp, "#{tracknum}_tracks.sqlite"))

          cmd_puts "      Done getting features."
        end
        if data_ids_with_wiggles.size > 0 then
          cmd_puts "      Getting wiggle files."
          gff_files = Array.new
          dbh_safe {
            @sth_get_wiggles_by_data_ids.execute data_ids_with_wiggles.uniq
            @sth_get_wiggles_by_data_ids.fetch_hash { |row|
              next if seen_wiggles.include?(row["wiggle_data_id"])
              seen_wiggles.push row["wiggle_data_id"]
              cmd_puts "        Finding metadata for wiggle files."
              tracknum = attach_generic_metadata(ap_ids, experiment_id, project_id, protocol_ids_by_column)
              cmd_puts "          Using tracknum #{tracknum}"
              cmd_puts "        Done."
              # Write out the current wiggle
              wiggle_db_file_path = File.join(output_dir, "#{tracknum}_%s.wigdb")
              wiggle_db_tmp_file_path = File.join(TrackFinder::gbrowse_tmp, "#{tracknum}_%s.wigdb")
              gff_file_path = File.join(output_dir, "#{tracknum}_wiggle.gff")
              gff_files.push(gff_file_path)
              cmd_puts "    Writing wigdb for wiggle file to: #{wiggle_db_tmp_file_path}"

              # Put the wiggle in a temp file for parsing
              wiggle_file = Tempfile.new('wiggle_file', TrackFinder::gbrowse_tmp)
              wiggle_file.puts row['wiggle_file']
              wiggle_file.close

              # TODO: Write the wiggle file locally, then move it to tracks dir
              # Do the conversion
              wiggle_writer = IO.popen("perl", "w")
              wiggle_writer.puts WIGGLE_TO_WIGDB_PERL + "\n\n"
              wiggle_writer.puts wiggle_db_tmp_file_path
              wiggle_writer.puts gff_file_path
              wiggle_writer.puts row['term']
              wiggle_writer.puts tracknum
              wiggle_writer.puts wiggle_file.path
              wiggle_writer.close


              # Remove the temporary source file
              wiggle_file.unlink
              # Move the output file to the output_dir
              wildcard_tmp = sprintf(wiggle_db_tmp_file_path, "*")
              cmd_puts "        Moving #{wildcard_tmp} to #{output_dir}."
              Dir.glob(wildcard_tmp).each { |filename|
                File.dirname(wildcard_tmp)
                cmd_puts "          Moving file #{filename} to #{File.join(output_dir, filename)}"
                FileUtils.mv(filename, output_dir)
              }
              cmd_puts "        Done."
              # Label this as a wiggle track
              TrackTag.new(
                :experiment_id => experiment_id,
                :name => 'Track Type',
                :project_id => project_id,
                :track => tracknum,
                :value => 'wiggle',
                :cvterm => 'track_type',
                :history_depth => 0
              ).save
            }
          }
          cmd_puts "      Done getting wiggle files."

          # TODO: Merge any wiggle tracks that are just one-per-chromosome
          new_gffs = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = Array.new } }
          gff_files.each { |gff_file|
            f = File.new(gff_file);
            lines = f.readlines
            f.close
            if lines.size == 3 then
              tracknum = gff_file.match(/\/(\d+)_wiggle\.gff/)[1]
              name = lines.last.match(/\tName=([^;]+)/)[1]
              new_gffs[name]["tracknums"].push tracknum
              new_gffs[name]["lines"].push lines.last
              new_gffs[name]["files"].push gff_file
              File.unlink(gff_file)
            end
          }
          new_gffs.each_pair { |name, info|
            # Delete all but one metadata
            cmd_puts "Merging all chromosomes from tracks #{info["tracknums"].join(", ")} for #{name} into a single track: #{info["tracknums"].first}."
            first_track_num = info["tracknums"].shift
            info["tracknums"].each { |tracknum|
              TrackTag.delete_all "project_id = #{project_id} AND track = #{tracknum}"
            }
            # Generate the new GFF
            tracknum = first_track_num
            gff_file_path = File.join(output_dir, "#{tracknum}_wiggle.gff")
            f = File.new(gff_file_path, "w")
            f.puts "#gff-version 3"
            f.puts ""
            info["lines"].each { |line| f.puts line }
          }
        end
        if data_ids_with_wiggles.size <= 0 && data_ids_with_features.size <= 0 then
          cmd_puts "      There are no features or wiggle files."
        end
      end
    end
    cmd_puts "  Done."
    ####### /Find Features/Wiggles #######
  end
  def recursive_output(seen_feature_ids, sth_get_gff, gff_file, parent_id = nil)
    if !parent_id.nil? then
      sth_get_gff.execute parent_id
    else
      return unless seen_feature_ids.size > 0
      sth_get_gff.execute seen_feature_ids.shift
    end
    row = sth_get_gff.fetch
    parents = row[1].nil? ? '' : row[1].split(',').map { |parent| parent.split('/') }
    parents.each { |reltype, parent_id|
      if seen_feature_ids.include?(parent_id) then
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
    feature['fmin'] = (feature['fmin'].to_i + 1).to_s unless feature['fmin'].nil? # Adjust coordinate system
    feature['fmin'] = '.' if feature['fmin'].nil?
    feature['fmax'] = '.' if feature['fmax'].nil?

    feature['srcfeature'] = feature['feature_id'] if feature['srcfeature'].nil?

    score = feature['score'] ? feature['score'] : "."
    out = "#{feature['srcfeature']}\t#{tracknum}_details\t#{feature['type']}\t#{feature['fmin']}\t#{feature['fmax']}\t#{score}\t#{feature['strand']}\t#{feature['phase']}\tID=#{feature['feature_id']}"

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
    gff_schema_loader.print LOAD_SCHEMA_TO_GFFDB_PERL + "\n\n"
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
      gff_loader.print LOAD_GFF_TO_GFFDB_PERL + "\n\n"
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

  # Track configuration
  def generate_gbrowse_conf(project_id)
    project = Project.find(project_id)

    dbinfo = TrackFinder.gbrowse_database
    gff_dbh = dbh_safe { DBI.connect(dbinfo[:ruby_dsn], dbinfo[:user], dbinfo[:password]) }

    schemas = self.get_experiments
    schema = "modencode_experiment_#{project_id}"
    experiment_id = schemas[schema][0]
    schema << "_data"

    tags = TrackTag.find_all_by_experiment_id(experiment_id, :select => "DISTINCT(track), null AS cvterm")

    tracknums = tags.map { |t| t.track }.uniq

    return {} if dbh_safe { gff_dbh.execute("SET search_path = #{schema}") } === false
    sth_get_types = dbh_safe { gff_dbh.prepare("SELECT tag FROM typelist WHERE tag LIKE '%:' || ? OR tag LIKE '%:' || ? || '_details'") }
    types = Array.new
    tracknums.each do |tracknum|
      sth_get_types.execute(tracknum, tracknum)
      sth_get_types.fetch do |row|
        types.push row[0]
      end
    end
    dbh_safe { sth_get_types.finish }

    track_defs = Hash.new

    sth_get_num_located_types = dbh_safe { gff_dbh.prepare("SELECT COUNT(*) FROM locationlist l INNER JOIN feature f ON l.id = f.seqid INNER JOIN typelist tl ON f.typeid = tl.id WHERE tl.tag = ? AND l.seqname = ANY(?)") }

    default_organism = "Drosophila melanogaster"
    types.each do |type|

      # Make sure this feature type is located to a chromosome
      sth_get_num_located_types.execute(type, TrackFinder::CHROMOSOMES)
      count = sth_get_num_located_types.fetch[0]
      next unless count > 0

      matchdata = type.match(/(.*):((\d*)(_details)?)$/)
      track_type = matchdata[1]
      track_source = matchdata[2]
      tracknum = matchdata[3]

      key = "#{project.id} #{project.name[0..10]} #{track_type}:#{tracknum}"

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
      zoomlevels = [ nil ]
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
          sort_order = 'sub ($$) {shift->feature->name cmp shift->feature->name}'
        else
          # GFF-only
          unique_analyses = TrackTag.find_all_by_experiment_id_and_track_and_cvterm(experiment_id, tracknum.to_i, 'unique_analysis')
          unique_analyses = unique_analyses.size > 1 ? unique_analyses.map { |tt| tt.value }.uniq : nil
        end
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
          track_defs[stanzaname]['category'] = "Preview"
          track_defs[stanzaname]['feature'] = type
          track_defs[stanzaname]['fgcolor'] = fgcolor
          track_defs[stanzaname]['bgcolor'] = bgcolor
          track_defs[stanzaname]['stranded'] = 0
          track_defs[stanzaname]['group_on'] = group_on
          track_defs[stanzaname]['label_transcripts'] = label_transcripts
          track_defs[stanzaname]['database'] = "modencode_preview_#{project.id}"
          track_defs[stanzaname]['key'] = key
          track_defs[stanzaname]['citation'] = citation_text
          track_defs[stanzaname]['label'] = label
          track_defs[stanzaname]['bump density'] = 250
          track_defs[stanzaname]['label density'] = 100
          track_defs[stanzaname]['glyph'] = glyph
          track_defs[stanzaname]['connector'] = connector
          track_defs[stanzaname][:unique_analyses] = unique_analyses unless unique_analyses.nil?

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
        else
          track_defs[stanzaname][:semantic_zoom][zoomlevel] = Hash.new
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['feature'] = type
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
        end
      }
    end

    track_defs.each do |stanzaname, config|
      config[:organism] = default_organism if config[:organism].nil?
    end

    return track_defs
  end
end
