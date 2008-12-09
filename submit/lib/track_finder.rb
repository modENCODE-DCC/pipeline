require 'applied_protocol'
require 'rubygems'
require 'dbi'
require 'cgi'
require 'pg_database_patch'
require 'find'

class TrackFinder
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

  TRACKS_PER_COLUMN = 5
  MAX_FEATURES_PER_CHR = 10000
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
    $startmin = $start if ($start < $startmin) || (!defined($startmin));
    $endmax = $end if ($end > $endmax) || (!defined($endmax));
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
  print GFF $loader->featurefile('gff3', $gff_type, $source);
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

  def initialize(command_object = nil)
    dbinfo = self.database
    @command_object = command_object
    @dbh = DBI.connect(dbinfo[:dsn], dbinfo[:user], dbinfo[:password])
  end

  def search_path=(search_path)
      dbh_safe { @dbh.do "SET search_path = #{search_path}, wiggle, pg_catalog" }
  end

  def find_tracks(experiment_id)
    cmd_puts "Loading feature and wiggle data into GBrowse database..."
    sth_datums = dbh_safe { 
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

    sth_features = dbh_safe { 
      @dbh.prepare("SELECT
                   d.heading || ' [' || CASE WHEN d.name IS NULL THEN '' ELSE d.name END || ']' AS data_name,
                   f.feature_id,
                   f.name, f.uniquename,
                   cvt.name AS type,
                   fl.fmin, fl.fmax, fl.strand, fl.phase,
                   src.name AS srcfeature,
                   srctype.name AS srctype
                   FROM data_feature df
                   INNER JOIN feature f ON f.feature_id = df.feature_id
                   INNER JOIN cvterm cvt ON f.type_id = cvt.cvterm_id
                   INNER JOIN data d ON df.data_id = d.data_id
                   LEFT JOIN featureloc fl ON df.feature_id = fl.feature_id
                   LEFT JOIN feature src ON src.feature_id = fl.srcfeature_id
                   LEFT JOIN cvterm srctype ON src.type_id = srctype.cvterm_id
                   WHERE df.data_id = ANY(?)") 
    }
    sth_parts_of_features = dbh_safe {
      @dbh.prepare("SELECT
                   fr.object_id AS parent_id,
                   f.feature_id,
                   f.name, f.uniquename,
                   cvt.name AS type,
                   fl.fmin, fl.fmax, fl.strand, fl.phase,
                   src.name AS srcfeature,
                   srctype.name AS srctype,
                   frtype.name AS relationship_type
                   FROM feature f
                   INNER JOIN cvterm cvt ON f.type_id = cvt.cvterm_id
                   INNER JOIN feature_relationship fr ON fr.subject_id = f.feature_id
                   INNER JOIN cvterm frtype ON fr.type_id = frtype.cvterm_id
                   LEFT JOIN featureloc fl ON f.feature_id = fl.feature_id
                   LEFT JOIN feature src ON src.feature_id = fl.srcfeature_id
                   LEFT JOIN cvterm srctype ON src.type_id = srctype.cvterm_id
                   WHERE fr.object_id = ANY(?)")
    }

    sth_wiggles = dbh_safe { 
      @dbh.prepare("SELECT 
                   d.heading || ' [' || CASE WHEN d.name IS NULL THEN '' ELSE d.name END || ']' AS data_name,
                   wiggle_data.name, 
                   wiggle_data.wiggle_data_id,
                   wiggle.aswiggletext(wiggle_data.wiggle_data_id) AS wiggle_file,
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

    cmd_puts "  Detecting tracks included in submission."
    usable_tracks = find_usable_tracks(experiment_id)
    cmd_puts "  Done."
    cmd_puts "  Finding features and wiggle files attached to tracks."
    # Get all of the datums of all protocols
    found_tracks = Hash.new { |hash, protocol_column| hash[protocol_column] = Hash.new }
    dbh_safe {
      usable_tracks.each do |col, set_of_tracks|
        set_of_tracks.each do |applied_protocols|
          # Get the outputs for the applied_protocol
          ap_ids = applied_protocols.map { |ap| ap.applied_protocol_id }
          sth_datums.execute(ap_ids)

          data_ids_with_features = Array.new
          data_ids_with_wiggles = Array.new

          sth_datums.fetch_hash do |row|
            if row['number_of_features'].to_i > 0 then
              data_ids_with_features.push row["data_id"].to_i
            elsif row['number_of_wiggles'].to_i > 0 then
              data_ids_with_wiggles.push row["data_id"].to_i
            end
          end

          features = Hash.new { |hash, datum_name| hash[datum_name] = Array.new }
          wiggles = Hash.new { |hash, datum_name| hash[datum_name] = Array.new }
          parent_feature_ids = Hash.new
          cmd_puts "    Getting features."
          if data_ids_with_features.size > 0 then
            sth_features.execute data_ids_with_features.uniq
            sth_features.fetch_hash { |row| 
              feature_hash = row
              feature_hash["children"] = Array.new
              feature_hash["parents"] = Array.new
              parent_feature_ids[row["feature_id"]] = feature_hash
              features[row["data_name"]].push feature_hash if feature_hash['fmin'] && feature_hash['fmax']
            }
          end



          while parent_feature_ids.keys.size > 0
            sth_parts_of_features.execute parent_feature_ids.keys
            new_parent_feature_ids = Hash.new
            sth_parts_of_features.fetch_hash { |row|
              subfeature_hash = row.reject { |column, value| column == "object_id" }
              subfeature_hash["children"] = Array.new
              subfeature_hash["parents"] = Array.new

              new_parent_feature_ids[row["feature_id"]] = subfeature_hash

              subfeature_hash["data_name"] = parent_feature_ids[row["parent_id"]]["data_name"]
              
              # Add this feature to the relationships from the previous pass
              parent_feature_ids[row["parent_id"]]["children"].push [row["relationship_type"], subfeature_hash]
              subfeature_hash["parents"].push [row["relationship_type"], parent_feature_ids[row["parent_id"]]]

              features[subfeature_hash["data_name"]].push subfeature_hash if subfeature_hash['fmin'] && subfeature_hash['fmax']
            }
            parent_feature_ids = new_parent_feature_ids
          end
          cmd_puts "    Done."

          cmd_puts "    Getting wiggle files."
          if data_ids_with_wiggles.size > 0 then
            sth_wiggles.execute data_ids_with_wiggles.uniq
            sth_wiggles.fetch_hash { |row| wiggles[row["data_name"]].push row.reject { |column, value| column == "data_name" } }
          end
          cmd_puts "    Done."

          # Remove default value from hash
          wiggles.default = nil
          features.default = nil

          cmd_puts "    For the protocol in column #{col}:"
          if features.size > 0 then
            cmd_puts "      There are #{features.size} features."
            features.each_pair do |datum_name, features|
              found_tracks[col][datum_name] = Array.new unless found_tracks[col][datum_name]
              found_tracks[col][datum_name].push({
                :experiment_id => experiment_id,
                :type => :feature,
                :name => datum_name,
                :data => features,
                :applied_protocol_ids => applied_protocols.map { |ap| ap.applied_protocol_id }
              })
            end
          end
          if wiggles.size > 0 then
            cmd_puts "      There are #{wiggles.size} wiggle files."
            wiggles.each_pair do |datum_name, wiggles|
              found_tracks[col][datum_name] = Array.new unless found_tracks[col][datum_name]
              found_tracks[col][datum_name].push({
                :experiment_id => experiment_id,
                :type => :wiggle,
                :name => datum_name,
                :data => wiggles,
                :applied_protocol_ids => applied_protocols.map { |ap| ap.applied_protocol_id }
              })
            end
          end
          if wiggles.size <= 0 && features.size <= 0 then
            cmd_puts "      There are no features or wiggle files."
          end

        end
      end
    }

    cmd_puts "  Done."
    return found_tracks
  end

  def find_usable_tracks(experiment_id)

    usable_tracks = Hash.new { |hash, column| hash[column] = Array.new }
    cmd_puts "    Scanning protocols for inputs or outputs that could make tracks."
    applied_protocols = Hash.new { |hash, ap_id| hash[ap_id] = AppliedProtocol.new(:applied_protocol_id => ap_id) }

    # Get all the applied protocols for this experiment
    # Start with the first set of applied protocols
    dbh_safe { 
      sth_aps = @dbh.prepare("SELECT 
                             eap.first_applied_protocol_id,
                             apd.data_id AS input_data_id,
                             p.name AS protocol_name
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
      end
    }

    # Then follow the applied_protocol->datum->applied_protocol link
    column = 0
    dbh_safe {
      sth_aps = @dbh.prepare("SELECT 
                             apd_next.applied_protocol_id AS next_applied_protocol,
                             apd_next_all.data_id AS input_data_id,
                             p.name AS protocol_name
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
          end
        end
        column = column + 1
      end
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

    cmd_puts "\n      " + (usable_tracks.sort_by { |col, set_of_tracks| col }.map { |col, set_of_tracks| "Protocol #{col} has #{set_of_tracks.size} set(s) of potential track(s)" }.join(", "))
    cmd_puts "    Done."
    return usable_tracks
  end

  def generate_output(found_tracks, directory = '.')

    Dir.mkdir(directory) unless File.directory? directory
    found_tracks.keys.each do |column|
      cmd_puts "For protocol in column #{column}:"
      found_tracks[column].each_pair do |datum_name, tracks|
        tracks.each do |track_descriptor|
          if track_descriptor[:type] == :feature then
            cmd_puts "  There are #{track_descriptor[:data].size} features for the #{track_descriptor[:name]} track"


            merged_features = Hash.new
            track_descriptor[:data].each do |feature|
              if merged_features.has_key? feature['feature_id'] then
                # Two locations?
                seen_feature = merged_features[feature['feature_id']]
                if seen_feature['fmin'] != feature['fmin'] || seen_feature['fmax'] != feature['fmax'] || seen_feature['srcfeature'] != feature['srcfeature'] then
                  if seen_feature['srctype'] == "chromosome_arm" then
                    # The seen_feature is the match vs. the chromosome
                    seen_feature['target'] = "#{feature['srcfeature']} #{feature['fmin']} #{feature['fmax']}"
                  elsif feature['srctype'] == "chromosome_arm" then
                    # The seen_feature is the match vs. the target, because the current feature is the match vs. the chromosome
                    feature['target'] = "#{seen_feature['srcfeature']} #{seen_feature['fmin']} #{seen_feature['fmax']}"
                    merged_features[feature['feature_id']] = feature
                  end
                  # else skip
                end
              else
                merged_features[feature['feature_id']] = feature
              end
            end
            
            cmd_puts  "    There are #{merged_features.size} features after removing duplicate features"

            too_many_features = false
            if merged_features.size > MAX_FEATURES_PER_CHR then
              # Figure out how many features there are per chromosome
              count = Hash.new { |hash, srcfeature| hash[srcfeature] = 0 }
              merged_features.values.each { |f|
                count[f['srcfeature']] += 1 unless f['srcfeature'].nil?
              }
              if count.values.find { |num_feats| num_feats > MAX_FEATURES_PER_CHR } then
                too_many_features = true
                # Wigglefy
                # One wiggle db file per chr and feature type
                # One GFF per track
                unique_types = track_descriptor[:data].map { |feature| feature['type'] }.uniq
                chromosomes = count.keys

                # Make a GFF for wigglefied tracks ALSO
                gff_file = File.new(File.join(directory, "#{track_descriptor[:tracknum]}_wiggle.gff"), "w")
                gff_file.puts("##gff-version 3")
                unique_types.each do |type|

                  chromosomes.each do |chromosome|
                    wiggle_db_file_path = File.join(directory, "#{track_descriptor[:tracknum]}_#{chromosome}_#{type}.wigdb")

                    wiggle_writer = IO.popen("perl", "w")
                    wiggle_writer.print GFF_TO_WIGDB_PERL + "\n\n"
                    wiggle_writer.puts wiggle_db_file_path
                    wiggle_writer.puts chromosome
                    min = 0
                    max = 255
                    wiggle_writer.puts "#{min} #{max}"
                    fmin = nil
                    fmax = nil
                    track_descriptor[:data].find_all { |feature| feature['type'] == type && feature['srcfeature'] == chromosome }.each do |feature|
                      if feature['fmin'] && feature['fmax'] then
                        wiggle_writer.puts "#{(feature['fmin'].to_i+1).to_s} #{feature['fmax']} #{max}"
                        
                        fmin = [ feature['fmin'].to_i, feature['fmax'].to_i, fmin.to_i ].reject { |a| a <= 0 }.min
                        fmax = [ feature['fmin'].to_i, feature['fmax'].to_i, fmax.to_i ].reject { |a| a <= 0 }.max
                      end
                    end
                    wiggle_writer.close
                    gff_file.puts "#{chromosome}\t#{track_descriptor[:tracknum]}\t#{type}\t#{fmin}\t#{fmax}\t.\t.\t.\tName=#{track_descriptor[:name]};wigfile=#{wiggle_db_file_path}"
                  end
                end
                gff_file.close
              end
            end

            gff_file = File.new(File.join(directory, "#{track_descriptor[:tracknum]}.gff"), "w")
            gff_file.puts("##gff-version 3")
            merged_features.values.each { |f| if f['srcfeature'].nil? then f['srcfeature'] = f['uniquename'] end }

            while merged_features.size > 0
              if too_many_features then
                out = feature_to_gff(merged_features, "#{track_descriptor[:tracknum]}_details")
              else
                out = feature_to_gff(merged_features, track_descriptor[:tracknum])
              end
              gff_file.puts(out)
            end
            gff_file.close
          end

          # Input was wiggle:
          if track_descriptor[:type] == :wiggle then
            cmd_puts "  There are #{track_descriptor[:data].size} wiggles for the #{track_descriptor[:name]} track"

            wiggle_db_file_path = File.join(directory, "#{track_descriptor[:tracknum]}_%s.wigdb")
            gff_file_path = File.join(directory, "#{track_descriptor[:tracknum]}_wiggle.gff")
            track_descriptor[:data].sort { |w1, w2| w1['wiggle_data_id'] <=> w2['wiggle_data_id'] }.each do |wiggle|
              # Write out the wiggle file as a wigdb with GFF
              cmd_puts "    Writing wigdb for wiggle file to: #{wiggle_db_file_path}"

              # Create temp file
              wiggle_file = Tempfile.new('wiggle_file')
              wiggle_file.puts wiggle['wiggle_file']
              wiggle_file.close

              # Run wiggle-db converter
              wiggle_writer = IO.popen("perl", "w")
              wiggle_writer.print WIGGLE_TO_WIGDB_PERL + "\n\n"
              wiggle_writer.puts wiggle_db_file_path
              wiggle_writer.puts gff_file_path
              wiggle_writer.puts wiggle['term']
              wiggle_writer.puts track_descriptor[:tracknum]
              wiggle_writer.puts wiggle_file.path
              wiggle_writer.close
            end
          end

          # Write metadata tags
          cmd_puts "  Saving metadata to database."
          dbh_safe {
            track_descriptor[:tags].each { |experiment_id, value, type, history_depth|
              TrackTag.new(
                :project_id => experiment_id,
                :track => track_descriptor[:tracknum],
                :value => value,
                :cvterm => type,
                :history_depth => history_depth
              ).save
            }
          }
        end
      end
    end
  cmd_puts "Done finding tracks."
  end

  def feature_to_gff(features, tracknum, parent_id = nil)
    if parent_id.nil? then
      (feature_id, feature) = features.shift
    else
      feature = features.delete(parent_id)
    end

    # Format for GFF
    feature['uniquename'] = (feature['uniquename'].gsub(/[;=\[\]\/, ]/, '_'))
    feature['name'] = (feature['name'].gsub(/[;=\[\]\/, ]/, '_')) unless feature['name'].nil?
    feature['strand'] = 0 if feature['strand'].nil?
    feature['srcfeature'] = feature['uniquename'] if feature['srcfeature'].nil?
    case feature['strand'].to_i
    when -1 then feature['strand'] = '-'
    when 1 then feature['strand'] = '+'
    else feature['strand'] = '.'
    end
    feature['phase'] = '.' if feature['phase'].nil?
    feature['fmin'] = '.' if feature['fmin'].nil?
    feature['fmax'] = '.' if feature['fmax'].nil?

    # Write out GFF
    srcfeature = (feature['srcfeature'] == feature['uniquename']) ? feature['srcfeature'] : feature['feature_id']
    out = "#{feature['srcfeature']}\t#{tracknum}\t#{feature['type']}\t#{feature['fmin']}\t#{feature['fmax']}\t.\t#{feature['strand']}\t#{feature['phase']}\tID=#{srcfeature}"
    out = out + ";Name=#{feature['name']}" unless feature['name'].nil?
    out = out + ";Target=#{feature['target']}" unless feature['target'].nil?
  
    # Parental relationships
    feature['parents'].each do |reltype, parent|
      # Make sure the parent is written before this feature
      out = feature_to_gff(features, tracknum, parent['feature_id']) + out if features[parent['feature_id']]
      # Write the parental relationship
      out = out + ";Parent=#{parent['feature_id']}"
      out = out + ";parental_relationship=#{reltype}/#{parent['feature_id']}"
    end

    out = out + "\n"

#    feature["feature_relationships"].each { |type, child|
#      out = out + "\n" + feature_to_gff(child, tracknum, type, feature)
#    }
    out
  end

  def get_experiments
    schemas = dbh_safe {
      sth_schemas = @dbh.prepare "SELECT DISTINCT schemaname FROM pg_views WHERE schemaname LIKE 'modencode_experiment_%' AND schemaname NOT LIKE 'modencode_experiment_%_data'"
      schemas = Hash.new
      sth_schemas.execute
      sth_schemas.fetch do |row|
        schemas[row[0]] = nil
      end

      schemas.keys.each do |schema|
        sth_experiments = @dbh.prepare "SELECT DISTINCT experiment_id, uniquename FROM #{schema}.experiment"
        sth_experiments.execute
        schemas[schema] = sth_experiments.fetch
      end
      schemas.reject { |sch, exp| exp.nil? }
    }
  end

  def delete_tracks(project_id, directory)
    tags = TrackTag.find_all_by_project_id(project_id)

    Find.find(directory) do |path|
      Find.prune if File.directory?(path) && path != directory # Don't recurse
      if File.basename(path) =~ /^\d+[_\.]/ then
        File.unlink(path)
      end
    end
    TrackTag.destroy_all "project_id = #{project_id}"
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
  def attach_metadata(found_tracks)
    # Attach experiment # to track def
    sth_metadata = dbh_safe {
      @dbh.prepare "SELECT
      --cur_output_data.heading || ' [' || CASE WHEN cur_output_data.name IS NULL THEN '' ELSE cur_output_data.name END || ']' AS data_name,
      cur_output_data.value AS data_value,
      cur_output_data_type.name AS data_type,
      prev_apd.applied_protocol_id AS prev_applied_protocol_id,
      attr.value AS attr_value, attr_type.name AS attr_type

      FROM applied_protocol cur
      LEFT JOIN (applied_protocol_data cur_apd 
        INNER JOIN (data cur_output_data
          LEFT JOIN cvterm cur_output_data_type ON cur_output_data.type_id = cur_output_data_type.cvterm_id
          LEFT JOIN (data_attribute da
            INNER JOIN attribute attr ON da.attribute_id = attr.attribute_id
            INNER JOIN cvterm attr_type ON attr_type.cvterm_id = attr.type_id
          ) ON da.data_id = cur_output_data.data_id
        ) ON cur_apd.data_id = cur_output_data.data_id
        LEFT JOIN applied_protocol_data prev_apd ON cur_apd.data_id = prev_apd.data_id AND prev_apd.direction = 'output'
      ) ON cur_apd.applied_protocol_id = cur.applied_protocol_id AND cur_apd.direction = 'input'


      WHERE cur.applied_protocol_id = ANY(?)"
    }

    cmd_puts "Finding metadata for tracks."
    metadata  = Hash.new

    seen_ap_sets = Hash.new
    found_tracks.keys.each do |column|
      found_tracks[column].each_pair do |datum_name, tracks|
        tracks.each do |track_descriptor|
          tracknum = self.get_next_tracknum
          #track_descriptor = { :type => , :name => , :data => , :applied_protocol_ids => }
          tags = seen_ap_sets[track_descriptor[:applied_protocol_ids]]
          tags = Array.new if tags.nil?

          # Get all of the metadata associated with this and other applied protocols
          ap_ids = track_descriptor[:applied_protocol_ids]
          history_depth = 0
          # Iterate through previous applied protocols
          while ap_ids.size > 0
            prev_ap_ids = Array.new
            dbh_safe {
              sth_metadata.execute(ap_ids)
              sth_metadata.fetch do |row|
                tags.push [ track_descriptor[:experiment_id], row['data_value'], row['data_type'], history_depth ] unless row['data_value'].nil? || row['data_value'].empty?
                # Get data attributes
                tags.push [ track_descriptor[:experiment_id], row['attr_value'], row['attr_type'], history_depth ] unless row['attr_value'].nil? || row['attr_value'].empty?
                prev_ap_ids.push row['prev_applied_protocol_id'] unless row['prev_applied_protocol_id'].nil?
              end
            }
            ap_ids = prev_ap_ids.uniq
            history_depth = history_depth + 1
          end
          # Add a tag for every feature (name as value, type as type)
          if track_descriptor[:type] == :feature then
            track_descriptor[:data].each do |feature|
              tags.push [ track_descriptor[:experiment_id], feature['name'], feature['type'], 0 ]
            end
          end
          tags.push [ track_descriptor[:experiment_id], track_descriptor[:type].to_s, 'track_type', 0 ]
          track_descriptor[:tags] = tags.uniq
          track_descriptor[:tracknum] = tracknum
        end
      end
    end
  end

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
  def gbrowse_database
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
  def load_into_gbrowse(project_id, directory)
    schemas = self.get_experiments
    experiment_id = schemas["modencode_experiment_#{project_id}"][0]
    tags = TrackTag.find_all_by_project_id(experiment_id, :select => "DISTINCT(track), null AS cvterm")
    tracknums = tags.map { |t| t.track }.uniq

    gff_files = Hash.new { |hash, key| hash[key] = Array.new }
    Find.find(directory) do |path|
      Find.prune if File.directory?(path) && path != directory # Don't recurse
      if matchdata = File.basename(path).match(/^(\d*)(_.*)?\.gff/) then
        gff_files[matchdata[1]].push path if tracknums.include? matchdata[1].to_i
      end
    end
    schema = "modencode_experiment_#{project_id}_data"
    dbinfo = gbrowse_database

    schema_ddl = ''
    File.open(File.join(TrackFinder::gbrowse_root, 'ddl/data_schema_with_replaceable_names.sql')) { |ddl_file|
      schema_ddl = ddl_file.read.gsub(/\$temporary_chado_schema_name\$/, schema)
    }
    # Can't execute multiple statements (e.g. DDL) in Ruby DBI
    gff_schema_loader = IO.popen("perl", "w")
    gff_schema_loader.print LOAD_SCHEMA_TO_GFFDB_PERL + "\n\n"
    gff_schema_loader.puts dbinfo[:perl_dsn]
    gff_schema_loader.puts dbinfo[:user]
    gff_schema_loader.puts dbinfo[:password]
    gff_schema_loader.puts "DROP SCHEMA IF EXISTS #{schema} CASCADE;"
    gff_schema_loader.puts(schema_ddl);
    gff_schema_loader.close

    gff_files.map { |k, v| v }.flatten.each do |gff_file|
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
  end
  def generate_gbrowse_conf(project_id)
    project = Project.find(project_id)

    dbinfo = gbrowse_database
    gff_dbh = dbh_safe { DBI.connect(dbinfo[:ruby_dsn], dbinfo[:user], dbinfo[:password]) }

    schemas = self.get_experiments
    schema = "modencode_experiment_#{project_id}"
    experiment_id = schemas[schema][0]
    schema << "_data"

    tags = TrackTag.find_all_by_project_id(experiment_id, :select => "DISTINCT(track), null AS cvterm")

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

    track_defs = Hash.new

    types.each do |type|
      matchdata = type.match(/(.*):((\d*)(_details)?)$/)
      track_type = matchdata[1]
      track_source = matchdata[2]
      tracknum = matchdata[3]

      key = "#{project.id} #{project.name[0..8]} #{track_type}:#{tracknum}"

      min_score = nil
      max_score = nil
      neg_color = nil
      pos_color = nil
      fgcolor = "black"
      glyph = "generic"
      label = "sub { return shift->name; }"
      connector = "solid"
      connector_color = "solid"
      zoomlevels = [ nil ]
      case track_type
      when "match" then
        glyph = "segments"
        label = "sub { my $f = shift; foreach (@{$f->each_tag_value('Target')}) { s/\s+\d+\s+\d+\s*$//g; return $_; } }"
      when "histone_binding_site" then
        glyph = "segments"
        label = track_type
        connector = "0"
        connector_color = "white"
      when "TF_binding_site" then
        glyph = "segments"
        label = track_type
        connector = "0"
        connector_color = "white"
      when "binding_site" then
        glyph = "segments"
        label = track_type
        connector_color = "white"
      when "transcript_region" then
        glyph = "segments"
        fgcolor = "lightgrey"
      when "transcript" then
        glyph = "processed_transcript"
      when "gene" then
        glyph = "gene"
        zoomlevels = [ nil, 101, 10001, 100001 ]
      end

      stanzaname = "#{project.name[0..8]}_#{track_type.gsub(/:/, '_')}_#{tracknum}_#{project.id}"

      if track_source !~ /\d*_details/ then
        # If this is not a details track...
        if types.find { |other_type| other_type == "#{track_type}:#{tracknum}_details" } then
          # ...but there is a details track for this feature type, then the
          # current track is the wiggle view for features that are 
          # a GFF file when zoomed in
          zoomlevels = [ 10001 ]
          glyph = "wiggle_density"
        end
      end
      
      tag_track_type = TrackTag.find_by_project_id_and_track_and_cvterm(experiment_id, tracknum.to_i, 'track_type')
      if tag_track_type then
        if tag_track_type.value == "wiggle" then
          glyph = "wiggle_xyplot"
          min_score = -20
          max_score = 20
          neg_color = "orange"
          pos_color = "blue"
        end
      end

      track_defs[stanzaname] = Hash.new if track_defs[stanzaname].nil?
      track_defs[stanzaname][:semantic_zoom] = Hash.new if track_defs[stanzaname][:semantic_zoom].nil?
      zoomlevels.each { |zoomlevel|
        if zoomlevel.nil? then
          track_defs[stanzaname]['category'] = "Preview"
          track_defs[stanzaname]['feature'] = type
          track_defs[stanzaname]['fgcolor'] = fgcolor
          track_defs[stanzaname]['database'] = "modencode_preview_#{project.id}"
          track_defs[stanzaname]['key'] = key
          track_defs[stanzaname]['label'] = label
          track_defs[stanzaname]['bump density'] = 250
          track_defs[stanzaname]['label density'] = 100
          track_defs[stanzaname]['glyph'] = glyph
          track_defs[stanzaname]['connector'] = connector
          track_defs[stanzaname]['min_score'] = min_score unless min_score.nil?
          track_defs[stanzaname]['max_score'] = max_score unless max_score.nil?
          track_defs[stanzaname]['neg_color'] = neg_color unless neg_color.nil?
          track_defs[stanzaname]['pos_color'] = pos_color unless pos_color.nil?
        else
          track_defs[stanzaname][:semantic_zoom][zoomlevel] = Hash.new
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['feature'] = type
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['label'] = label
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['glyph'] = glyph
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['fgcolor'] = fgcolor
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['min_score'] = min_score unless min_score.nil?
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['max_score'] = max_score unless max_score.nil?
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['neg_color'] = neg_color unless neg_color.nil?
          track_defs[stanzaname][:semantic_zoom][zoomlevel]['pos_color'] = pos_color unless pos_color.nil?
        end
      }
    end

    return track_defs
  end
  def cmd_puts(message)
    return if @command_object.nil?
    @command_object.stdout = @command_object.stdout + message + "\n";
    @command_object.save
  end
end
