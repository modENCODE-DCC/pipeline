require 'applied_protocol'
require 'rubygems'
require 'dbi'
require 'cgi'
require 'pg_database_patch'
require 'find'


class TrackFinderFast < TrackFinder

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
                   HAVING 
                     count(wig.*) > 0 OR 
                     COUNT(df.*) > 0 OR 
                     c.name = 'Sequence_Alignment/Map (SAM)'") 
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
                   UNION SELECT null, -1, 'eof', null, null, null
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
  # Track finding and output
  def attach_generic_metadata(experiment_id, project_id, protocol_ids_by_column)
    tracknum = self.get_next_tracknum
    @sth_get_all_metadata = @dbh.prepare("SELECT
                                         data.value AS data_value,
                                         data_type.name AS data_type,
                                         db.description AS db_type,
                                         db.url AS db_url,
                                         attr.value AS attr_value, attr.heading AS attr_name
                                         FROM data
                                         INNER JOIN cvterm data_type ON data.type_id = data_type.cvterm_id
                                         LEFT JOIN (dbxref dbx INNER JOIN db ON dbx.db_id = db.db_id) ON dbx.dbxref_id = data.dbxref_id
                                         LEFT JOIN (data_attribute da
                                           INNER JOIN attribute attr ON da.attribute_id = attr.attribute_id
                                         ) ON da.data_id = data.data_id
                                         ")
    @sth_get_all_metadata.execute
    seen_data = Hash.new { |h, k| h[k] = Hash.new }
    row = @sth_get_all_metadata.fetch_hash
    cmd_puts "        Getting metadata for reagents."
    i=0
    while (!row.nil?) do
      i+=1 
      datum = { 
        :value => row["data_value"],
        :type => row["data_type"],
        :url => row["db_url"],
        :db_type => row["db_type"],
        :attrs => Hash.new
      }
      while (!row.nil? && row["data_value"] == datum[:value] && row["data_type"] == datum[:type]) do
        cmd_puts "          #{i.to_s}" if (i % 1000 == 0)
        datum[:attrs][row["attr_name"]] = row["attr_value"]
        row = @sth_get_all_metadata.fetch_hash
      end
      unless seen_data[datum[:value]][datum[:type]]
        seen_data[datum[:value]][datum[:type]] = true
        # Datum name
        TrackTag.new(
         :experiment_id => experiment_id,
         :name => datum[:value][0...255],
         :project_id => project_id,
         :track => tracknum,
         :value => datum[:value][0...255],
         :cvterm => datum[:type],
         :history_depth => 0
        ).save
        # Datum URL prefix (for wiki links)
        TrackTag.new(
          :experiment_id => experiment_id,
          :name => datum[:value][0...255],
          :project_id => project_id,
          :track => tracknum,
          :value => datum[:url],
          :cvterm => 'data_url',
          :history_depth => 0
        ).save unless datum[:db_type] != "URL_mediawiki_expansion"
        # Datum attributes
        datum[:attrs].each { |name, value|
          TrackTag.new(
            :experiment_id => experiment_id,
            :name => datum[:value][0...255],
            :project_id => project_id,
            :track => tracknum,
            :value => value,
            :cvterm => name,
            :history_depth => 0
          ).save unless value.nil? || value.empty?
        }
      end
    end
    cmd_puts "        Done."

    cmd_puts "        Getting citation text and referenced submissions."
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
    cmd_puts "        Done."

    return tracknum
  end
  def generate_track_files_and_tags(experiment_id, project_id, output_dir)
    ######## Find Features/Wiggles #######

    seen_wiggles = Array.new
    seen_sams = Array.new

    # Get applied protocols -- this replaces get_usable_tracks
    @sth_all_aps = @dbh.prepare("SELECT applied_protocol_id FROM applied_protocol")
    @sth_all_aps.execute
    ap_ids = @sth_all_aps.fetch_all.map { |row| row["applied_protocol_id"] }

    @sth_all_protocols = @dbh.prepare("SELECT protocol_id FROM protocol")
    @sth_all_protocols.execute
    protocol_ids_by_column = { 0 => (@sth_all_protocols.fetch_all.map { |row| row["protocol_id"] }) }
    #/end get applied protocols

    cmd_puts "  Finding features, wiggle files, and SAM files attached to tracks."
    found_any_tracks = false

    tracknum_to_data_name = Hash.new
    prevalence = Hash.new
    @sth_get_type_prevalence = @dbh.prepare("SELECT cvt.cvterm_id, cvt.name, COUNT(f.feature_id) AS COUNT 
                               FROM feature f INNER JOIN cvterm cvt ON f.type_id = cvt.cvterm_id
                               GROUP BY cvt.name, cvt.cvterm_id ORDER BY COUNT(f.feature_id)") 
    @sth_get_type_prevalence.execute
    @sth_get_type_prevalence.fetch_hash { |row| prevalence[row["name"]] = row["count"] }
    made_gff_file = nil
    if (prevalence.keys & [ "match", "match_part" ]).size > 0 then
      cmd_puts "    Finding match and match_part features."
      # Has some ESTs and/or matches
      cmd_puts "      Finding metadata."
      tracknum = attach_generic_metadata(experiment_id, project_id, protocol_ids_by_column)
      cmd_puts "      Done."
      tracknum_to_data_name[tracknum] = "match/match_part"
      @sth_get_matches = @dbh.prepare("
                                      SELECT 
                                      f.feature_id, f.name, f.uniquename, f.organism_id,
                                      cvt.name AS type,
                                      fl.fmin, fl.fmax, fl.strand, fl.phase, fl.rank, fl.residue_info,
                                      fp.value AS propvalue, fp.rank AS proprank, fptype.name AS propname,
                                      a.program AS analysis, af.rawscore, af.normscore, af.significance, af.identity,

                                      src.feature_id AS src_id, src.name AS src_name, src.uniquename AS src_uniquename,
                                      src_type.name AS src_type,
                                      src_loc.fmin AS src_fmin, src_loc.fmax AS src_fmax, src_loc.strand AS src_strand, src_loc.phase AS src_phase, src_loc.rank AS src_rank,
                                      src_fp.value AS src_propvalue, src_fp.rank AS src_proprank, src_fptype.name AS src_propname

                                      FROM feature f
                                      INNER JOIN cvterm cvt ON f.type_id = cvt.cvterm_id
                                      INNER JOIN featureloc fl ON f.feature_id = fl.feature_id
                                      LEFT JOIN (featureprop fp
                                        INNER JOIN cvterm fptype ON fp.type_id = fptype.cvterm_id
                                      ) ON f.feature_id = fp.feature_id
                                      LEFT JOIN (analysisfeature af 
                                        INNER JOIN analysis a ON af.analysis_id = a.analysis_id
                                      ) ON f.feature_id = af.feature_id
                                      INNER JOIN feature src ON fl.srcfeature_id = src.feature_id
                                      INNER JOIN cvterm src_type ON src.type_id = src_type.cvterm_id
                                      LEFT JOIN featureloc src_loc ON src.feature_id = src_loc.feature_id
                                      LEFT JOIN (featureprop src_fp
                                        INNER JOIN cvterm src_fptype ON src_fp.type_id = src_fptype.cvterm_id
                                      ) ON src.feature_id = src_fp.feature_id

                                      WHERE cvt.name = 'match' OR cvt.name = 'match_part' ORDER BY f.feature_id, src_id
                                      ")

      analyses = Hash.new
      organisms = Hash.new
      made_gff_file = File.join(output_dir, "#{tracknum}.gff")
      found_any_tracks = true
      gff_file = File.new(made_gff_file, "w")
      gff_file.puts "##gff-version 3"
      cmd_puts "        Creating GFF file."
      seen_feature_ids = Hash.new
      seen_srcfeature_ids = Hash.new
      @sth_get_matches.execute
      row = @sth_get_matches.fetch_hash
      i=0
      while (!row.nil?) do
        i += 1
        cmd_puts "          #{i.to_s}" if (i % 10000 == 0)
        feature = { 
          :feature_id => row["feature_id"],
          :name => row["name"],
          :uniquename => row["uniquename"],
          :type => row["type"],
          :analysis => row["analysis"],
          :score => row["rawscore"],
          :normscore => row["normscore"],
          :identity => row["identity"],
          :significance => row["significance"],
          :props => Hash.new { |h, k| h[k] = Array.new },
          :loc => Hash.new
        }
        srcfeatures = Hash.new { |h, k| h[k] = Hash.new }
        analyses[row["analysis"]] = true
        organisms[row["organism_id"]] = true
        while (!row.nil? && row["feature_id"] == feature[:feature_id]) do
          
          srcfeatures[row["src_id"]][:feature_id] = row["src_id"]
          srcfeatures[row["src_id"]][:name] = row["src_name"]
          srcfeatures[row["src_id"]][:uniquename] = row["src_uniquename"]
          srcfeatures[row["src_id"]][:type] = row["src_type"]
          srcfeatures[row["src_id"]][:rank] = row["rank"].to_i
          srcfeatures[row["src_id"]][:props] = Hash.new { |h, k| h[k] = Array.new } if srcfeatures[row["src_id"]][:props].nil?
          srcfeatures[row["src_id"]][:loc] = Hash.new if srcfeatures[row["src_id"]][:loc].nil?

          feature[:props][row["propname"]].push row["propvalue"] unless row["propvalue"].nil?
          feature[:loc][row["rank"].to_i] = { :fmin => row["fmin"], :fmax => row["fmax"], :strand => row["strand"], :phase => row["phase"], :residue => row["residue_info"] }

          srcfeatures[row["src_id"]][:props][row["src_propname"]].push row["src_propvalue"] unless row["src_propvalue"].nil?
          srcfeatures[row["src_id"]][:loc][row["src_rank"].to_i] = { :fmin => row["src_fmin"], :fmax => row["src_fmax"], :strand => row["src_strand"], :phase => row["src_phase"], :residue => row["src_residue_info"] }
          row = @sth_get_matches.fetch_hash
        end
        srcfeatures.each { |src_id, srcfeature|
          unless seen_srcfeature_ids[srcfeature[:feature_id]] then
            seen_srcfeature_ids[srcfeature[:feature_id]] = true
            srcfeature[:srcfeature] = srcfeature[:name]
            srcfeature[:fmin] = srcfeature[:loc][0][:fmin]
            srcfeature[:fmax] = srcfeature[:loc][0][:fmax]
            srcfeature[:strand] = srcfeature[:loc][0][:strand]
            srcfeature[:phase] = srcfeature[:loc][0][:phase]
            gff_file.puts feature_to_gff(srcfeature, tracknum)
          end
        }
        srcfeature = srcfeatures.values.find { |sf| sf[:rank] == 1 }
        feature[:fmin] = feature[:loc][0][:fmin]
        feature[:fmax] = feature[:loc][0][:fmax]
        feature[:strand] = feature[:loc][0][:strand]
        feature[:phase] = feature[:loc][0][:phase]
        feature[:target] = "#{srcfeature[:name]} #{feature[:loc][1][:fmin].to_i+1} #{feature[:loc][1][:fmax]}"
        feature[:target_accession] = srcfeature[:uniquename]
        gff_file.puts feature_to_gff(feature, tracknum)
      end
      gff_file.close

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

      if made_gff_file then
        # Generate a wiggle file
        cmd_puts "        Generating a wiggle file for zoomed-out views."
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
        gff_file = File.open(made_gff_file, "r")
        gff_file.each { |line|
          cols = line.split(/\t/)
          row = { :fmin => line[3], :fmax => line[4], :srcfeature => line[0] }
          if row[:fmin] && row[:fmax] && CHROMOSOMES.include?(row[:srcfeature]) then
            wiggle_writer = wiggle_writers[row['srcfeature']][row['type']]
            wiggle_writer[:writer].puts "#{(row[:fmin].to_i+1).to_s} #{row[:fmax]} 255"
            wiggle_writer[:fmin] = [ row[:fmin].to_i, row[:fmax].to_i, wiggle_writer[:fmin].to_i ].reject { |a| a <= 0 }.min
            wiggle_writer[:fmax] = [ row[:fmax].to_i, row[:fmax].to_i, wiggle_writer[:fmax].to_i ].reject { |a| a <= 0 }.max
          end
        }
        gff_file.close

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
        gff_file.close
        cmd_puts "        Done."
        cmd_puts "      Done."
      end

#          TODO: Uncomment
#          File.unlink(File.join(TrackFinderFast::gbrowse_tmp, "#{tracknum}_tracks.sqlite"))

      cmd_puts "      Done getting features."

      data_ids_with_wiggles = Array.new
      data_ids_with_sam_files = Array.new
      @sth_get_data = @dbh.prepare("SELECT d.data_id, COUNT(wig.*) AS number_of_wiggles, c.name AS type
                             FROM data d
                             INNER JOIN cvterm c ON d.type_id = c.cvterm_id
                             LEFT JOIN data_wiggle_data wig ON wig.data_id = d.data_id
                             GROUP BY d.data_id, c.name
                             HAVING 
                               count(wig.*) > 0 OR 
                               c.name = 'Sequence_Alignment/Map (SAM)'") 
      @sth_get_data.execute
      @sth_get_data.fetch_hash do |row|
        if row['number_of_wiggles'].to_i > 0 then
          data_ids_with_wiggles.push row["data_id"].to_id
        elsif row['type'] == "Sequence_Alignment/Map (SAM)" then
          data_ids_with_sam_files.push row["data_id"]
        end
      end

      if data_ids_with_wiggles.size > 0 then
        found_any_tracks = true
        cmd_puts "      Getting wiggle files."
        gff_files = Array.new
        dbh_safe {
          @sth_get_wiggles_by_data_ids.execute data_ids_with_wiggles.uniq
          @sth_get_wiggles_by_data_ids.fetch_hash { |row|
            next if seen_wiggles.include?(row["wiggle_data_id"])
            wiggle_filename = row["data_value"]
            seen_wiggles.push row["wiggle_data_id"]
            cmd_puts "        Finding metadata for wiggle files."
            tracknum = attach_generic_metadata(experiment_id, project_id)
            cmd_puts "          Using tracknum #{tracknum}"
            cmd_puts "        Done."
            # Write out the current wiggle
            wiggle_db_file_path = File.join(output_dir, "#{tracknum}_%s.wigdb")
            wiggle_db_tmp_file_path = File.join(TrackFinderFast::gbrowse_tmp, "#{tracknum}_%s.wigdb")
            gff_file_path = File.join(output_dir, "#{tracknum}_wiggle.gff")
            gff_files.push(gff_file_path)
            cmd_puts "    Writing wigdb for wiggle file to: #{wiggle_db_tmp_file_path}"

            # Put the wiggle in a temp file for parsing
            unless row["cleaned_wiggle_file"] then
              wiggle_file = Tempfile.new('wiggle_file', TrackFinderFast::gbrowse_tmp)
              wiggle_file.puts row['wiggle_file']
              wiggle_file.close
            else
              wiggle_file_path = File.join(ExpandController.path_to_project_dir(Project.find(project_id)), "extracted", row["cleaned_wiggle_file"])
              wiggle_file = File.open(wiggle_file_path, "r")
            end

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
            unless row["cleaned_wiggle_file"] then
              wiggle_file.unlink
            end
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
              :value => 'wiggle',
              :cvterm => 'track_type',
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
        found_any_tracks = true
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
            cmd_puts "          Copying BAM file(s) to tracks dir."
            [ row["sorted_bam_file"], "#{row["sorted_bam_file"]}.bai" ].each { |f|
              FileUtils.cp(
                File.join(ExpandController.path_to_project_dir(Project.find(project_id)), "extracted", bam_file_subdir, f),
                File.join(ExpandController.path_to_project_dir(Project.find(project_id)), "tracks", File.basename(f))
              )
            }
            cmd_puts "          Done."
            cmd_puts "        Finding metadata for SAM files."
            tracknum = attach_generic_metadata(experiment_id, project_id)
            cmd_puts "          Using tracknum #{tracknum}"
            cmd_puts "        Done."

            # Label this as a SAM track
            TrackTag.new(
              :experiment_id => experiment_id,
              :name => 'BAM File',
              :project_id => project_id,
              :track => tracknum,
              :value => row["sorted_bam_file"],
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
    unless found_any_tracks then
      # Generate a citation even though we didn't find any tracks
      cmd_puts "    No tracks found for this submission; generating generic metadata for citation."
      ap_ids = usable_tracks.map { |col, set_of_tracks| set_of_tracks.map { |aps| aps.map { |ap| ap.applied_protocol_id } }.flatten }.flatten
      tracknum = attach_generic_metadata(experiment_id, project_id)
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
  def feature_to_gff(feature, tracknum)
    # Format GFF fields for output
    feature[:uniquename] = (feature[:uniquename].gsub(/[;=\[\]\/, ]/, '_'))
    feature[:name] = (feature[:name].gsub(/[;=\[\]\/, ]/, '_')) unless feature[:name].nil?
    feature[:strand] = 0 if feature['strand'].nil?
    case feature[:strand].to_i
    when -1 then feature[:strand] = '-'
    when 1 then feature[:strand] = '+'
    else feature[:strand] = '.'
    end
    feature[:phase] = '.' if feature[:phase].nil?
    feature[:fmin] = '.' if feature[:fmin].nil?
    feature[:fmax] = '.' if feature[:fmax].nil?

    feature[:srcfeature] = feature[:feature_id] if feature[:srcfeature].nil?

    score = feature[:score] ? feature[:score] : "."
    out = "#{feature[:srcfeature]}\t#{tracknum}_details\t#{feature[:type]}\t#{feature[:fmin] == "." ? "." : (feature[:fmin].to_i+1)}\t#{feature[:fmax]}\t#{score}\t#{feature[:strand]}\t#{feature[:phase]}\tID=#{feature[:feature_id]}"

    # Build the attributes column
    if !feature[:name].nil? && feature[:name].length > 0 then
      out = out + ";Name=#{feature[:name][0...128]}"
    elsif !feature[:uniquename].nil? && feature[:uniquename].length > 0 then
      out = out + ";Name=#{feature[:uniquename][0...128]}"
    end
    out = out + ";Target=#{feature[:target]}" unless feature[:target].nil?
    out = out + ";target_accession=#{feature[:target_accession]}" unless feature[:target_accession].nil?
    out = out + ";analysis=#{feature[:analysis]}" unless feature[:analysis].nil?
    out = out + ";normscore=#{feature[:normscore]}" unless feature[:normscore].nil?
    out = out + ";identity=#{feature[:identity]}" unless feature[:identity].nil?
    out = out + ";significance=#{feature[:significance]}" unless feature[:significance].nil?

    # Parental relationships
#    feature["parents"].each do |reltype, parent|
#      # Write the parental relationship
#      out = out + ";Parent=#{parent}"
#      out = out + ";parental_relationship=#{reltype}/#{parent}"
#    end

    # Attributes
    feature[:props].each do |propname, propvalues|
      out = out + ";#{propname.downcase.gsub(/[^A-Za-z0-9]/, "_")}="
      out = out + propvalues.map { |val| val.gsub(/[,;]/, "_") }.join(",")
    end

    out
  end
end
