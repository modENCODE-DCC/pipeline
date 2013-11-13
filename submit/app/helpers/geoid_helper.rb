require 'fileutils'
require 'pp'
require 'rubygems'
require 'dbi'
require 'dbd/Pg'
require "#{RAILS_ROOT}/lib/dbi_patch.rb" if File.exists? "#{RAILS_ROOT}/lib/dbi_patch.rb"
module GeoidHelper

# Geoid marshal basename
GEOID_MARSHAL = "geoid_updates.marshal"


### Helpers from common_funcs.rb ###
	class SDRFHeader
		def initialize(heading, name=nil)
			@num_splits = Hash.new
			@values = Array.new
			if name then
				@heading = heading
				@name = name
				@fullname = @heading + (@name.nil? ? "" : " [#{@name}]")
			else
				m = heading.match(/([^\[]*)(\[(.*)\])?/)
				@heading = m[1].gsub(/^\s*|\s*$/, '')
				@name = m[3]
				@fullname = heading
			end
		end
		def values
			@values
		end
		def heading
			@heading
		end
		def name
			@name
		end
		def fullname
			@fullname
		end
		def rows
			@values.size
		end
		def add_split(item)
			@num_splits[item] = true
		end
		def num_splits
			@num_splits.keys.size
		end
		def split_example
			@num_splits.keys.first
		end
		def uniq_rows
			r = Hash.new
			@values.each_index { |i|
				v = @values[i]
				r[v] ||= Array.new
				r[v].push i
			}
			r.values.sort { |a, b| a[0] <=> b[0] }
		end
		def to_s
			"(#{self.num_splits.to_s})" + @heading + (@name.nil? ? "" : " [#{@name}]") + "==" + self.split_example
		end
		def has_quotes?
			@has_quotes
		end
		def has_quotes!
			@has_quotes = true
		end
	end

	def get_geo_type_id(db)
		sth_get_cvterm = db.prepare("SELECT cvterm_id FROM cvterm WHERE name = 'GEO_record'")
		sth_get_cv = db.prepare("SELECT cv_id FROM cv WHERE name = 'modencode'")
		sth_get_db = db.prepare("SELECT db_id FROM db WHERE name = 'modencode'")
		sth_get_dbxref = db.prepare("SELECT dbxref_id FROM dbxref INNER JOIN db ON dbxref.db_id = db.db_id WHERE db.name = 'modencode' AND dbxref.accession = '0000109'")

		sth_make_db = db.prepare("INSERT INTO db (name, description, url) VALUES('modencode', 'OBO', 'http://wiki.modencode.org/project/extensions/DBFields/ontologies/modencode-helper.obo')")
		sth_make_dbxref = db.prepare("INSERT INTO dbxref (db_id, accession) VALUES(?, '0000109')")
		sth_make_cv = db.prepare("INSERT INTO cv (name) VALUES('modencode')")
		sth_make_cvterm = db.prepare("INSERT INTO cvterm (cv_id, dbxref_id, name) VALUES(?, ?, 'GEO_record')")

		sth_get_cvterm.execute
		if (row = sth_get_cvterm.fetch_hash) then
			cvterm_id = row["cvterm_id"]
		else
			# Make a CVTerm
			# Got a CV?
			sth_get_cv.execute
			if (row = sth_get_cv.fetch_hash) then
				cv_id = row["cv_id"]
			else
				# Make a CV
				sth_make_cv.execute
				sth_get_cv.execute; row = sth_get_cv.fetch_hash; throw :wtf_no_cv if row.nil?
				cv_id = row["cv_id"]
			end

			# .. and DBXref?
			sth_get_dbxref.execute
			if (row = sth_get_dbxref.fetch_hash) then
				dbxref_id = row["dbxref_id"]
			else
				# Make a dbxref
				# Got a DB?
				sth_get_db.execute
				if (row = sth_get_db.fetch_hash) then
					db_id = row["db_id"]
				else
					# Make a DB
					sth_make_db.execute
					sth_get_db.execute; row = sth_get_db.fetch_hash; throw :wtf_no_db if row.nil?
					db_id = row["db_id"]
				end
				# Make a DBXref
				sth_make_dbxref.execute(db_id)
				sth_get_dbxref.execute; row = sth_get_dbxref.fetch_hash; throw :wtf_no_dbxref if row.nil?
				dbxref_id = row["dbxref_id"]
			end

			# Make a CVTerm
			sth_make_cvterm.execute(cv_id, dbxref_id)
			sth_get_cvterm.execute; row = sth_get_cvterm.fetch_hash; throw :wtf_no_cvterm if row.nil?
			cvterm_id = row["cvterm_id"]
		end

		sth_get_cvterm.execute
		row = sth_get_cvterm.fetch_hash

		# Clean up handles
		sth_get_cvterm.finish; sth_get_cv.finish; sth_get_db.finish; sth_get_dbxref.finish
		sth_make_cvterm.finish; sth_make_cv.finish; sth_make_db.finish; sth_make_dbxref.finish

		throw :wtf_still_no_cvterm if cvterm_id.nil?
		return cvterm_id
	end


  ### helpers from find_replicates.rb ###
  
  def parse_sdrf(filename)
    f = File.open(filename)

    record_seps = [ $/, "\r\n", "\r", "\n" ]
    has_quotes = false
    header = nil
    while header.nil? && !record_seps.empty? do
      separator = record_seps.shift
      line = f.readline(separator)
      if f.eof? then
        # SDRF should be longer than one line; bad newline found?
        f.rewind
        next
      end
      # Split drops trailing null fields here.
      header = line.chomp.split(/\t/).map { |k|
        has_quotes = true if (k =~ /^"|"$/)
        SDRFHeader.new(k.gsub(/^"|"$/, ''))
      }
    end
    header.each { |s| s.has_quotes! } if has_quotes
  
    f.each(separator) { |line|
      line.chomp!
      # Split with limit of -1 to prevent suppression of trailing null fields
      # since they are something we ACTUALLY WANT TO KEEP
      # if they represent (nil) fields covered under the header
      items = line.split(/\t/, -1).map { |k| k.gsub(/^"|"$/, '') }
      i = 0 # Save the highest index
      items.each_index { |i|
        # What if this line has more items than the header?
        if i >= header.length then
          next if items[i].empty? # Let it go if they're trailing tabs that are ACTUALLY bonus
          throw :found_more_sdrf_row_items_than_header_entries # Bonus nonempty item -- wtf?
          # Previously would have thrown a 'nil object when you didn't expect' error.
        end
        header[i].add_split(items[i])
        header[i].values.push items[i]
      }
      # If we haven't gotten to the end of header yet (ie, not enough fields in the line!) 
      # add empty-string fields to pad it out.
      ((i+1)...header.length).each{|j|
        fr_puts "Item expected at header index #{j} but not found! Padding row with an empty item."
        header[j].add_split ""
        header[j].values.push ""
      }
    }
  
    header
  end
  # Print the sdrf, optionally overwriting an existing sdrf
  def print_sdrf(sdrf, outfile, ok_to_overwrite)
    has_quotes = true if sdrf.find { |h| h.has_quotes? }
    throw :not_overwriting if (!ok_to_overwrite && outfile && File.exists?(outfile))
    f = outfile.nil? ? $stdout : File.new(outfile, "w")
    if has_quotes then
      f.puts sdrf.map { |h| '"' + h.fullname + '"' }.join("\t")
    else
      f.puts sdrf.map { |h| h.fullname }.join("\t")
    end
    sdrf_rows = sdrf[0].rows
    (0..(sdrf_rows-1)).each { |i|
      if has_quotes then
        f.puts sdrf.map { |h| '"' + h.values[i] + '"' }.join("\t")
      else
        f.puts sdrf.map { |h| h.values[i] }.join("\t")
      end
    }
    f.close
  end
  def make_chadoxml(h, level = 0)
    h.map { |k, v|
      k = k.sub(/#.*/, '')
      xml = (" "*level) + "<#{k}>"
      if v.is_a?(Hash) then
        xml += "\n" + make_chadoxml(v, level+2) + "\n" + (" "*level)
      else
        xml += v.to_s
      end
      xml += "</#{k.match(/\w*/)[0]}>"
    }.join("\n")
  end

  # If passed a calling command, puts it to that command's stdout
  # Otherwise, just puts.
  def fr_puts input
    if @calling_command.nil? then
      puts input
    else
      @calling_command.stdout = "#{@calling_command.stdout}#{input}\n"
      @calling_command.save
    end
  end 

  # If running with a command, puts it to that command's stderr; alternatively puts to stderr.
  def fr_error input
    if  @calling_command.nil? then
      $stderr.puts input
    else
      @calling_command.stderr = "#{calling_command.stderr}#{input}\n"
      @calling_command.save
    end
  end
  def set_calling_command(cmd) # Set the calling command
    @calling_command = cmd
  end
### main from find_replicates.rb ###

  # This is effectively the main method from the find_replicates.rb file. With a few modifications
  # for whether it's being run in batch or on a  single proj.
  # params : no_db_commits = bool ; geoid_string , geoid_file , output_dir = string
  # and optional calling_command -- Command of some flavor
  # Exactly one of geoid_string and geoid_file should be passed --
  # if file is passed, it indicates a run in batchmode.
  # if calling_command is passed, output will be sent to that command's stdout.
  def find_replicates(params)
    unless ( params[:geoid_string].nil? ^ params[:geoid_file].nil?) then
      fr_puts "Received both a :geoid_string and :geoid_file parameter--exactly one is required! Aborting!"
      throw :needs_exactly_one_geoid_string_or_file
    end
    @batchmode = ! params[:geoid_file].nil?
    # If running in batch, set up the file to get geoids from
    if @batchmode then
      f = File.new(params[:geoid_file])
    else
      f = [params[:geoid_string]]
    end     
    output_basedir = Dir.new(params[:output_dir])
    # This ought to be a constant
    no_db_commits = params[:no_db_commits]
    @calling_command = params[:calling_command]

    all_infos = [] # All info hashs discovered 
    # Only save list of marshalled infos if in batchmode
    marshal_list = File.new(File.join(output_basedir.path, "marshal_list.txt"), "w") if @batchmode
   
    # For each line in the file (or the single array entry)
    # figure out what the geoids ought to be and stick them in a hash
    f.each { |line|
      line.chomp!
      (pid, gse, gsms, target_column, sdrf) = line.split(/\t/)
      gsms = gsms.split(/,/)
      
      info = {} # Hash containing calculated geoid information
      info[:pid] = pid

      header = parse_sdrf(sdrf)
      s = header.reverse

      fr_puts "modencode_#{pid} has #{gsms.size.inspect} GSMs" 
      fr_puts "and we have #{header[0].rows.inspect} rows"

      if gsms.size != header[0].rows then
        raise Exception.new("Must supply as many GSMS as rows! SDRF has #{header[0].rows} rows, but received #{gsms.size} GSMS.")
      end

      column_specified = false
      target_column = target_column.to_i
      
      colname = header[target_column].name
      if colname =~ /geo/i then
        fr_puts "Using existing GEOid column #{colname}"
      else
        fr_puts "Using protocol #{header[target_column].split_example}."
        column_specified = true
      end

      # if it's not geo, use it as protocol:
      if( column_specified ) then 
        
        # get previous_protocol (ie target) and the one after it
        previous_protocol = header[target_column]
        previous_protocol_name = previous_protocol.split_example unless previous_protocol.nil?
        next_protocol = header.slice(target_column +1, header.length).find{|col| col.heading =~ /Protocol REF/i}
        next_protocol_name = next_protocol.split_example unless next_protocol.nil?


        geo_record = SDRFHeader.new("Result Value", "geo record") # make a new column
        # populate the geo record
        gsms.each_index{|i|
          geo_record.values[i] = gsms[i]
        }
        fr_puts "      Setting GSMs to: " + geo_record.values.join(", ") 
        i = next_protocol.nil? ? header.size : header.find_index(next_protocol)
        header.insert(i, geo_record)
        fr_puts "  Attach GEO IDs to protocol: '#{previous_protocol.to_s}'" 
      else # there must be a geo colunn

        # finding a geo header index.
        geo_header_idx = s.find_index { |h| h.name =~ /geo/i }

        if geo_header_idx then
          previous_protocol = s.slice(geo_header_idx, s.length).find { |col| col.heading =~ /Protocol REF/i }; previous_protocol_name = previous_protocol.split_example unless previous_protocol.nil?
          next_protocol = s.slice(0, geo_header_idx).reverse.find { |col| col.heading =~ /Protocol REF/i }; next_protocol_name = next_protocol.split_example unless next_protocol.nil?
          # Attach GEO IDs to existing GEO ID column
          fr_puts "  Found existing GEO ID column for #{pid} between: '#{previous_protocol_name.to_s}' AND '#{next_protocol_name.to_s}'" 
          sdrf_rows = s[geo_header_idx].rows
          geo_header_col = s[geo_header_idx]

          if sdrf_rows != gsms.size then
            raise Exception.new("Can't match #{sdrf_rows} SDRF rows to #{gsms.size} GEO ids!")
            
            ## Attach GEO IDs, lining up duplicates with the previous row in the SDRF with the appropriate number of unique values
            #fr_puts "    There are more rows in the SDRF than GSM IDs: #{sdrf_rows} != #{gsms.size}." 
            # Have to line this up carefully
            #uniq_rows = enough_replicates_at.uniq_rows
            #fr_puts "      Unique rows for #{enough_replicates_at.heading} [#{enough_replicates_at.name}]: " + uniq_rows.pretty_inspect 
            #geo_header_col.values.clear
            #uniq_rows.each_index { |is_idx|
            #  uniq_rows[is_idx].each { |i|
            #    geo_header_col.values[i] = gsms[is_idx]
            #  }
            #}
            #fr_puts "      Setting GSMs to: " + geo_header_col.values.join(", ") 
          else
            # Attach GEO IDs to the SDRF in order
            geo_header_col.values.clear
            gsms.each_index { |i|
              geo_header_col.values[i] = gsms[i]
            }
            fr_puts "      Setting GSMs to: " + geo_header_col.values.join(", ") 
          end
          geo_record = geo_header_col
        else # No protocol column and no geo header idx. should never happen.
          raise Exception.new("No protocol column or existing GEO column was specified. This should never happen!")
        end
      end

      # If batchmode, make the project's subfolder within out
      output_sdrfdir = @batchmode ? File.join(output_basedir.path, pid.to_s) : output_basedir.path 
      FileUtils.mkdir_p(output_sdrfdir)
      out_sdrf = File.join(output_sdrfdir, File.basename(sdrf))

      # Create new SDRF, overwriting existing sdrf only if not in batchmode
      print_sdrf(header, out_sdrf, !@batchmode)

      info[:geo_header_col] = geo_header_col
      info[:geo_record] = geo_record
      info[:previous_protocol_name] = previous_protocol_name

      # stick info in the hash to be remembered
      all_infos << info
      # Write a marshal file
      marshal_filename = GEOID_MARSHAL
      out_marshal = File.join(output_sdrfdir, marshal_filename) 
      marshal_file = File.new(out_marshal, "w")
      marshal_file.puts(Marshal.dump(info))
      marshal_file.close
      
      marshal_list.puts File.join(pid.to_s, marshal_filename) if @batchmode 
    
    } 
    
    marshal_list.close if @batchmode
    
    # Then, run the database stuff on all_infos
    attached_geoids = update_db(all_infos, no_db_commits)
    attached_geoids
  end

  # This will make an array of geoid info for update_db when given
  # the path to a file -- can either be the marshal_list OR
  # a single marshal file. It figures it out!
  def make_geoid_info_from_marshal_list(list)
    if !File.exists?(list) then
      fr_error "No such list or marshal file #{list}"
      return nil
    end

    begin
      marshaled_info = Marshal.restore(File.open(list))
    rescue TypeError 
      # Assume it's a marshal list & proceed
    else # It worked -- it's a marshal file!
      return [marshaled_info]
    end

    # If we got here, it's a list file
    marshal_list = File.read(list).split($/).map { |f|
        if f =~ /^\// then
          f
        else
          File.join(File.dirname(list), f)
        end
      }
    marshal_list.each { |f|
      if !File.exists?(f) then
        fr_error "No such marshalled file: #{f}"
        return nil
      end
    }
    all_info = []
    marshal_list.each{ |f|
      all_info << Marshal.restore(File.open(f))
    }
    # return marshal infos
    all_info
  end

  # Helper -- get database info  
  def database
    if File.exists? "#{RAILS_ROOT}/config/idf2chadoxml_database.yml" then
      db_definition = open("#{RAILS_ROOT}/config/idf2chadoxml_database.yml") { |f| YAML.load(f.read)
     }
      dbinfo = Hash.new
      dbinfo[:dsn] = db_definition['ruby_dsn']
      dbinfo[:user] = db_definition['user']
      dbinfo[:password] = db_definition['password']
      return dbinfo
    else
      raise Exception.new("You need an idf2chadoxml_database.yml file in your config/ directory with at least a Ruby DBI dsn.")
    end
  end

  # Helpers for update_db -- any SQL.
  # They are broken out so they can be easily overridden in an external file if your DB has a different setup
  def  db_set_search_path(dbh, pid)
    dbh.execute("SET search_path = modencode_experiment_#{pid}_data")
  end

  # Find applied protocols with the correct name
  def db_find_protocol(dbh, pid, protocol_name)
    sth_find_protocol = dbh.prepare("SELECT ap.applied_protocol_id FROM applied_protocol ap 
                                    INNER JOIN protocol p ON ap.protocol_id = p.protocol_id WHERE p.name = ? 
                                    ORDER BY ap.applied_protocol_id")
    sth_find_protocol.execute(protocol_name)
    existing_aps = Array.new
    sth_find_protocol.fetch_hash { |row| existing_aps.push row }
    sth_find_protocol.finish
    existing_aps
  end
  # Gets the existing geo datums. Returns an array with them.
  def db_get_existing_record(dbh, pid, heading, name)
    sth_get_existing_record = dbh.prepare(
          "SELECT apd.applied_protocol_data_id, apd.direction, apd.applied_protocol_id, d.data_id, d.value 
           FROM applied_protocol_data apd INNER JOIN data d ON apd.data_id = d.data_id 
           WHERE d.heading = ? AND d.name = ? ORDER BY data_id")
    sth_get_existing_record.execute(heading, name)
    geo_id_data = Array.new
    sth_get_existing_record.fetch_hash { |row|
      geo_id_data.push(row)
    }
    sth_get_existing_record.finish
    geo_id_data
  end
  # returns a prepared sth of last_data_id
  def db_prepare_last_data_id(dbh)
    dbh.prepare("SELECT last_value FROM generic_chado.data_data_id_seq")
  end

  # reason should be a symbol.
  # This is so we can choose not to throw if we want to continue on
  def error_in_submission(pid, reason)
    throw reason
  end

  # Updates the database.
  
  # f = geo info. Can be a hash, array of hashes,
  # path to a marshal file, or path to a file containing
  # a list of marshal files. 
  # no_db_commits = whether to run commits or not
  def update_db(all_infos, no_db_commits)

    # We want to end up with an array of hashes f out of all this
    case all_infos.class.inspect
      when "Array" then
        # Assume it's the array of hashes we want.
        f = all_infos
      when "String" then
        # Assume it's a path to either marshal or marshal list
        f = make_geoid_info_from_marshal_list(all_infos)
      when "Hash" then
        # Assume it's an info hash and array it up
        f = [all_infos]
      else
        fr_error "Can't extract Geo ID information from #{all_infos.inspect}."
        return nil
    end

    if f.nil? then
      fr_error "Can't extract Geo ID information from #{all_infos.inspect}!"
      return nil
    end

    # Connect to database
    dbinfo = self.database
    db = DBI.connect(dbinfo[:dsn], dbinfo[:user], dbinfo[:password])
    db.execute("BEGIN TRANSACTION") if no_db_commits
  
    attached_geoids = Array.new
    
    # for each line, add the info to the DB
    f.each{|info|
      pid = info[:pid]
      geo_header_col = info[:geo_header_col]
      geo_record = info[:geo_record]
      previous_protocol_name = info[:previous_protocol_name]

      # Save the most recent set of geoids processed (or only, if not batchmode) to return later
      attached_geoids = geo_record.values

      # Database!
      db_set_search_path(db, pid)
      
      if (geo_header_col) then

        fr_puts "  Found an existing GEO datum; updating it and creating new ones as necessary" 
        geo_id_data = db_get_existing_record(db, pid, geo_header_col.heading, geo_header_col.name)

        # How many geo record datums already exist?
        unique_data = geo_id_data.map { |r| r["data_id"] }.uniq

        # Are there multiple geoIDs that could be collapsed to match the # of applied protocols?
        # For example, 4 APs and given geoIDs: A A B B C C A A (nonunique is okay here.)
        num_geoids = attached_geoids.length
        num_aps = geo_id_data.map { |r| r["applied_protocol_id"] }.uniq.length
        # If there are more geoids than applied protocols, but it's a multiple therof 
        if (num_geoids > num_aps) && ((num_geoids % num_aps) == 0)then
          dupefactor = num_geoids / num_aps
          deduped_geoids = []
          cant_dedupe_geoids = false
          current_geoid = nil
          attached_geoids.each_index{|idx|
            if (idx % dupefactor) == 0 then # Expecting a new GEO id
              current_geoid = attached_geoids[idx]
              deduped_geoids << current_geoid
            elsif ( current_geoid != attached_geoids[idx] ) then
            # Whoops, the geo ids don't line up like we expected
            # This will be caught lower down.
              cant_dedupe_geoids = true
              break
            end
          }
          unless (cant_dedupe_geoids) then
            fr_puts "    Found #{num_geoids} GEO ids for #{num_aps} applied protocols, but was" +
                    " able to remove duplicates and reduce length to #{deduped_geoids.length}!"
            fr_puts "    Previous GEO ids : \n#{attached_geoids.pretty_inspect}"
            fr_puts "    Reduced GEO ids : \n#{deduped_geoids.pretty_inspect}"
            attached_geoids = deduped_geoids
          end
        end

        if geo_id_data.size == attached_geoids.size || geo_id_data.size == attached_geoids.uniq.size then
          # Set the values in geo_id_data to be the geoIDs we want to put in the DB; clear data_id if 
          # we need to make a new datum.

          if geo_id_data.size == attached_geoids.uniq.size then
            attached_geoids.uniq!
          end

          if unique_data.size != 1 then
            if unique_data.size == attached_geoids.size then
              attached_geoids.each_index { |i| geo_id_data[i]["value"] = attached_geoids[i] }
            else
              # Are the IDs already in there?
              values = geo_id_data.map { |d| d["value"] }
              if values.sort == attached_geoids.sort then
                fr_puts "      All GEO IDs already in this submission!" 
                next
              else
                # Ok, the number of datums doesn't match up. Does the number of applied protocols
                # match up, and there are TOO FEW datums?
                unique_aps = geo_id_data.map { |r| r["applied_protocol_id"] }.uniq
                if (unique_data.size < attached_geoids.size) && (unique_aps.size == attached_geoids.size) then
                  # need to resort geo_id_data because data_id order is unusable since there are datums re-used
                  geo_id_data.sort!{|a, b| a["applied_protocol_id"].to_i <=> b["applied_protocol_id"].to_i }

                  # Update the geoID for each;
                  # if it's a repeat data_id, clear it--new datum is needed
                  geo_id_data.each_index {|i|
                    geo_id_data[i]["value"] = attached_geoids[i]
                    current_data_id = geo_id_data[i]["data_id"]
                    if geo_id_data.index{|j| j["data_id"] == current_data_id} < i then
                      geo_id_data[i]["data_id"] = nil
                    end
                  }
                  # Get current attributes of the existing datum if we're adding new datums.
                  if geo_id_data.map{|i| i["data_id"]}.include? nil then
                    sth_get_datum = db.prepare("SELECT * FROM data WHERE data_id = ?")
                    sth_get_datum.execute(geo_id_data.first["data_id"])
                    data_info = sth_get_datum.fetch_hash
                    sth_get_datum.finish
                  end
                else
                  # Give up 
                  fr_puts "      ERROR! Couldn't figure out how to map GeoIDs to the existing datums!" 
                  error_in_submission(pid, :more_than_one_unique_datum) # throws
                  next # skip this submission, if we choose not to throw an error
                end
              end
            end
          else
            attached_geoids.each_index { |i| geo_id_data[i]["value"] = attached_geoids[i] }
            # Update the existing one and add some more
            # 1. Get current attributes of the existing datum
            sth_get_datum = db.prepare("SELECT * FROM data WHERE data_id = ?")
            sth_get_datum.execute(geo_id_data.first["data_id"])
            data_info = sth_get_datum.fetch_hash
            sth_get_datum.finish
            # 2. Remove data_id from all but first data entry
            geo_id_data[1..-1].each { |d| d["data_id"] = nil }
          end

          # Insert and/or update
          sth_create = db.prepare("INSERT INTO data (name, heading, value, type_id, dbxref_id) VALUES(?, ?, ?, ?, ?)")
          sth_update = db.prepare("UPDATE data SET value = ? WHERE data_id = ?")
          sth_last_data_id = db_prepare_last_data_id(db) 
          sth_update_applied_protocol_data = db.prepare("UPDATE applied_protocol_data SET data_id = ? WHERE applied_protocol_data_id = ?")
          n=0
          geo_id_data.each { |d|
            if d["data_id"].nil? then
              # Create new datum
              fr_puts "    Creating datum for #{d["value"]}" 
              sth_create.execute(data_info["name"], data_info["heading"], d["value"], data_info["type_id"], data_info["dbxref_id"]) unless no_db_commits
              sth_last_data_id.execute unless no_db_commits
              last_id = sth_last_data_id.fetch_hash["last_value"] unless no_db_commits
              sth_update_applied_protocol_data.execute(last_id, d["applied_protocol_data_id"]) unless no_db_commits
            else
              # Update existing datum
              fr_puts "    Updating existing datum for #{d["value"]}" 
              sth_update.execute(d["value"], d["data_id"]) unless no_db_commits
            end
            n += 1
          }
          sth_create.finish
          sth_update.finish
          sth_last_data_id.finish
          sth_update_applied_protocol_data.finish
        else
          fr_puts "      More (or fewer) applied protocols using a GEO ID than GEO IDs to attach." 
          sth_update = db.prepare("UPDATE data SET value = ? WHERE data_id = ?")
          if unique_data.size == attached_geoids.size then
            fr_puts "        However, there are as many unique datum(s) as GEO IDs to attach." 
            sorted_data_ids = unique_data.sort
            sorted_data_ids.each_index { |i|
              data_id = sorted_data_ids[i]
              v = attached_geoids[i]
              fr_puts "        Updating datum to #{v}." 
              sth_update.execute(v, data_id) unless no_db_commits
            }
          elsif attached_geoids.uniq.size == 1
            fr_puts "        However, there is only 1 GEO ID to attach, so it is the same for all of them." 
            sorted_data_ids = unique_data.sort
            v = attached_geoids.first
            if geo_id_data.first["value"] == v then
              fr_puts "          Actually, that ID is already in the DB" 
            else
              sorted_data_ids.each { |data_id|
                fr_puts "        Updating datum to #{v}." 
                sth_update.execute(v, data_id) unless no_db_commits
              }
            end
          else
            fr_puts "        Fewer applied protocols for the datum than we expected:" 
            fr_puts geo_id_data.pretty_inspect 
            fr_puts "!=!=!=" 
            fr_puts attached_geoids.pretty_inspect 
            error_in_submission(pid, :wtf_they_dont_line_up) # throws
            next
          end
          sth_update.finish
        end
      else
        fr_puts "  No existing GEO datum, creating it/them" 
        existing_aps = db_find_protocol(db, pid, previous_protocol_name)

        if existing_aps.size == attached_geoids.size then
          # Sweet, there are as many APs as geo records
          use_these_gsms = attached_geoids
        elsif existing_aps.size == attached_geoids.uniq.size then
          # Okay, but it works for unique ones
          use_these_gsms = attached_geoids.uniq
        elsif attached_geoids.uniq.size == 1 then
          # Okay, there's only one GSM so we apply it to all APs
          gsm = attached_geoids.first
          use_these_gsms = existing_aps.map { gsm }
        else
          fr_puts "    #{existing_aps.size} APs for #{attached_geoids.size} GEO records" 
          error_in_submission(pid, :ap_size_differs_from_geo_record_count ) # throws
          next
        end
        # Create a new datum for each geo record in order and attach it to each applied_protocol as an output
        if use_these_gsms.size != existing_aps.size then
          error_in_submission(pid, :wtf_i_thought_i_just_set_ap_sizes) # throws
          next
        end

        geo_type_id = get_geo_type_id(db) unless no_db_commits

        sth_create_data = db.prepare("INSERT INTO data (heading, name, value, type_id) VALUES(?, ?, ?, ?)")
        sth_create_apd = db.prepare("INSERT INTO applied_protocol_data (applied_protocol_id, data_id, direction) VALUES(?, ?, 'output')")
        sth_last_data_id = db_prepare_last_data_id(db) 
        sth_datum_exists = db.prepare("SELECT data_id FROM data WHERE (name = 'geo record' or name = 'GEO id') AND value = ?")
        sth_apd_exists = db.prepare("SELECT applied_protocol_data_id FROM applied_protocol_data WHERE applied_protocol_id = ? AND data_id = ?")

        existing_aps.each_index { |i|
          ap = existing_aps[i]
          gsm = use_these_gsms[i]
          sth_datum_exists.execute(gsm)
          data_row = sth_datum_exists.fetch_hash
          if data_row then
            fr_puts "    Already a datum for #{gsm}" 
            data_id = data_row["data_id"]
          else
            fr_puts "    Creating a datum for #{gsm}" 
            sth_create_data.execute("Result Value", "geo record", gsm, geo_type_id) unless no_db_commits
            sth_last_data_id.execute unless no_db_commits
            data_id = sth_last_data_id.fetch_hash["last_value"] unless no_db_commits
          end
          sth_apd_exists.execute(ap["applied_protocol_id"], data_id)
          if sth_apd_exists.fetch_hash then
            fr_puts "      Already and applied_protocol_datum for #{gsm} and #{ap["applied_protocol_id"]}" 
          else
            fr_puts "      Creating applied_protocol_data entry for #{gsm} and #{ap["applied_protocol_id"]}" 
            sth_create_apd.execute(ap["applied_protocol_id"], data_id) unless no_db_commits
          end
        }
        sth_create_data.finish
        sth_create_apd.finish
        sth_last_data_id.finish
        sth_datum_exists.finish
        sth_apd_exists.finish
      end
      
    } 

    db.execute("ROLLBACK") if no_db_commits
    db.disconnect

    return attached_geoids
  end

end 
