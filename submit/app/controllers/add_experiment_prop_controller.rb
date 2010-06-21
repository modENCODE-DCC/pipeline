require "open3"
require "cgi"
require "chadoxml_listener"

class AddExperimentPropController < CommandController
  def initialize(options)
    super
    return unless options[:command].nil? # Set in CommandController if :command is given
    self.command_object = AddExperimentProp.new(options)
    command_object.command = options[:xml_path]
    command_object.save
    
  end

  def run
    super do
      self.command_object.status = AddExperimentProp::Status::PARSING
      self.command_object.save
      begin
        base_xmlfile = File.join(self.command_object.command, "#{self.command_object.project_id}.chadoxml")
        stream_parser = ChadoXMLListener.new(base_xmlfile)
        self.command_object.discovered_xml_elements = stream_parser.parse_file
        self.command_object.status = AddExperimentProp::Status::PARSED
        self.command_object.save
      rescue
        self.command_object.status = AddExperimentProp::Status::PARSING_FAILED
        self.command_object.save
      end
    end
  end

  def get_patches

  # Get the list of files in the directory self.command_object.command
  # Each patch file is known to be reasonably small, so we can use the
  # tree parser without loss of performance
    patch_list = []
    patch_files = get_patch_filenames()
    patch_files.each{|f|
      patch_xml = File.open(File.join(self.command_object.command, f)){|px| REXML::Document.new px}
      prop_name = patch_xml.elements["chadoxml/experiment/experiment_prop/name"].texts
      prop_value = patch_xml.elements["chadoxml/experiment/experiment_prop/value"].texts
      patch_list.push({:name => prop_name, :value => prop_value, :filename => f})
      }
    return patch_list
  end #get_patches

  # Get the name & value of each experiment-prop in the master list
  def get_props_in_master
    master_xmlfile = File.join(self.command_object.command, "applied_patches_#{self.command_object.project_id}.chadoxml")
    unless File.exists?(master_xmlfile) then
      return nil
    end
    master_content = File.open(master_xmlfile){|mxf| REXML::Document.new mxf }
    master_proplist = []
    master_content.elements.each("chadoxml/experiment/experiment_prop"){|exp|
      master_proplist.push({:name => exp.elements["name"], :value => exp.elements["value"]})
    } 
    return master_proplist
  end #get_props_in_master

  # Takes: the parameters for the new property
  # creates the XML document for the new patch
  def make_patch_file(params)
    # split the cvterm & dbxref params back into their 3 fields
    cvterm_fields = params["eprop_typeid"].split("/", 3)
    cvterm_fields.collect!{ |field| CGI.unescape(field)}
    # a dbxref of "///" indicates no dbxref
    unless params["eprop_dbxrefid"] == "///" then
      # Split the dbxref string into DB name/dbxref accession/dbxref version
      dbxref_fields = params["eprop_dbxrefid"].split("/", 3)
      dbxref_fields.collect!{ |field| CGI.unescape(field)}
    end
   
    # make an instance var for allowing the template access to the params
    @params = params
    @params["cvterm_fields"] = cvterm_fields
    @params["dbxref_fields"] = dbxref_fields
    
    # Render the chadoxml template file
    chadoxml_template_fullpath = "#{RAILS_ROOT}/app/views/pipeline/chadoxml_patch_template.chadoxml.erb"
    chadoxml_template = File.open(chadoxml_template_fullpath, 'r'){|f| f.read }
    erb_renderer = ERB.new(chadoxml_template)
    chadoxml_string = erb_renderer.result(binding)

    patchfile_path = File.join(self.command_object.command, get_next_patch_filename()) 
    write_patchfile = File.open(patchfile_path, 'w'){|wpf| wpf.write(chadoxml_string)}

  return chadoxml_string
  end # make_patch_file

  def get_patch_filenames
    all_files = Dir.entries(self.command_object.command)
    patch_files = all_files.select{|f| f =~ /^patch_\d+_#{self.command_object.project_id}\.chadoxml$/}
    patch_files.sort!
    return patch_files
  end # get_patch_filenames

  def get_next_patch_filename
    patch_files = get_patch_filenames()
    next_patch_number = 1
    unless patch_files == [] then
       

      # get out list of #s and sort
      patch_files.each{|pf| 
        pf.gsub!(/patch_/, "")
        pf.gsub!(/_#{self.command_object.project_id}\.chadoxml/, "")
      }
      patch_files.map!{|pf| pf.to_i}
      patch_files.sort!
      
      # find next number not on list
      next_patch_number =  patch_files.last + 1 
    end
    # construct filename & return
    return "patch_#{next_patch_number}_#{self.command_object.project_id}.chadoxml"
  end # get_next_patch_filename

  # Sorts out the checkmarks for inserting patches into the DB & deleting them
  def insertDB_and_delete(params)
    props_to_add = []
    props_to_delete = []
    result = ""
    params.each{|key, val|
      # if it matches add, add it to the DB
      if key =~ /^add_patch_\d+_#{self.command_object.project_id}\.chadoxml$/ then
       result += add_patch_to_db(key.gsub(/add_/, ""))
      # if it matches delete, delete the file
      elsif key =~ /^delete_patch_\d+_#{self.command_object.project_id}\.chadoxml$/ then
        result += delete_patchfile(key.gsub(/delete_/, ""))
      end
    }
    return result
  end #insertDB_and_delete
  
  def add_patch_to_db(patch_filename)
    full_patch_path = File.join(self.command_object.command, patch_filename)

    # Construct the command to add the patch to the DB

    loader =  "perl -I /var/www/pipeline/submit/script/loaders/modencode " +
    "/var/www/pipeline/submit/script/loaders/modencode/stag-storenode.pl "
    
    params = database
    schema = "-s \"modencode_experiment_#{self.command_object.project_id}\" "
    input_file = full_patch_path
    run_stag_storenode = "#{loader} #{params} #{schema} #{input_file}"
 
    (stag_stdout, stag_stderr) = Open3.popen3(run_stag_storenode){|stdin, stdout, stderr|
      [stdout.read, stderr.read] }
    
    # add patch data to master list
    add_to_master(full_patch_path)

    # delete patchfile
    delete_patchfile(patch_filename)

    return stag_stderr
   # return "Added #{full_patch_path} to database" # fix this
  end #add_patch_to_db

  # Adds the xml in the patch to the master list of patches
  # within the chadoxml tags (so it's all one parseable xml, theoretically)
  # TODO : test that the master created this way is loadable to the DB
  def add_to_master(full_patch_path)
    # If the master doesn't exist, create it with <chadoxml> tag
    master_xmlfile = File.join(self.command_object.command, "applied_patches_#{self.command_object.project_id}.chadoxml")
    unless File.exists?(master_xmlfile) then
     File.open(master_xmlfile, "w"){|mxf| mxf.puts "<chadoxml>\n</chadoxml>" }
    end
    
    # Get the contents of the patch to be added to the master file
    patchfile_contents =  ""
    File.open(full_patch_path, "r"){|pf|
    # Add each line to the string, except for the <chadoxml>tags
      while line = pf.gets
        patchfile_contents += line  unless line =~ /<\/*chadoxml>/
      end
    }
   
    # Store the updated master patchfile in a string
    master_with_new = "<chadoxml>\n"
    
    # First, open it to get the contents out
    File.open(master_xmlfile, "r+"){|mxf|
      # IF the first line isn't <chadoxml>, complain
      if mxf.gets != "<chadoxml>\n" then
        raise Exception "First line of master patch file was unexpected!"
      else
        # Add the patchfile data to the new master string,
        # then add the rest of the master file
        master_with_new += patchfile_contents
        while nextline = mxf.gets
            master_with_new += nextline
          end
      end
    }
    # Then, open it again, and write the new data to it.
    File.open(master_xmlfile, "w"){|mxf|
      mxf.puts master_with_new
    } 

  end # add_to_master


  def delete_patchfile(patch_filename)
    full_patch_path = File.join(self.command_object.command, patch_filename)
    begin
      File.delete(full_patch_path)
    rescue
      return "Error in deleting #{full_patch_path}: #{$!}\n"
    end
      return "Deleted patchfile #{patch_filename}\n"
  end #delete_patchfile

  private
  def database
    if File.exists? "#{RAILS_ROOT}/config/idf2chadoxml_database.yml" then
      db_definition = open("#{RAILS_ROOT}/config/idf2chadoxml_database.yml") { |f| YAML.load(f.read) }

      args = "-d=\"#{db_definition['perl_dsn']}\""
      args << " -user=\"#{db_definition['user']}\"" if db_definition['user']
      args << " -password=\"#{db_definition['password']}\"" if db_definition['password']
      return args
    else
      raise Exception("You need an idf2chadoxml_database.yml file in your config/ directory with at least a Perl DBI dsn.")
    end
  end

end
