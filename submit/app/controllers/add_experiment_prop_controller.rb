require "open3"
require "cgi"
require "chadoxml_listener"

class AddExperimentPropController
  def initialize(project, xml_path)
    @project = project
    @xml_path = xml_path
    
    base_xmlfile = File.join(xml_path, "#{@project.id}.chadoxml")
 
    @xml_base_content = File.open(base_xmlfile){|cxf| REXML::Document.new cxf}
    @master_xmlfile = File.join(@xml_path, "applied_patches_#{@project.id}.chadoxml")
    
    @stream_parser = ChadoXMLListener.new(base_xmlfile)

  end

  def parse_file
    @stream_parser.parse_file
  end

  def get_patches

  # Get the list of files in the directory @xml_path
  # Each patch file is known to be reasonably small, so we can use the
  # tree parser without loss of performance
    patch_list = []
    patch_files = get_patch_filenames()
    patch_files.each{|f|
      patch_xml = File.open(File.join(@xml_path, f)){|px| REXML::Document.new px}
      prop_name = patch_xml.elements["chadoxml/experiment/experiment_prop/name"].texts
      prop_value = patch_xml.elements["chadoxml/experiment/experiment_prop/value"].texts
      patch_list.push({:name => prop_name, :value => prop_value, :filename => f})
      }
    return patch_list
  end #get_patches

  # Get the name & value of each experiment-prop in the master list
  def get_props_in_master
    unless File.exists?(@master_xmlfile) then
      return "No patches have been applied to the database yet!"
    end
    master_content = File.open(@master_xmlfile){|mxf| REXML::Document.new mxf }
    master_proplist = []
    master_content.elements.each("chadoxml/experiment/experiment_prop"){|exp|
      master_proplist.push({:name => exp.elements["name"], :value => exp.elements["value"]})
    } 
    return master_proplist
  end #get_props_in_master

  # Returns a list of all experiments in the original xml file
  def get_experiments   
   return @stream_parser.all_experiments
  end # get_experiments

# Also get all the dbxrefs and cvterms so we can make dropdowns
# The stream parser's code makes assumptions about the structure of the xml file:
#   - All dbxrefs & cvterms are listed as direct children of <chadoxml>
#   - No macro (eg, <db>db_13</db>) appears earlier in the file than its
#       corresponding node
  
  def get_dbxrefs
    # Sort the dbxref by dbname => accession => version
    sorted_dbxrefs = @stream_parser.all_dbxrefs.sort{|a, b|
      retval = 0
      dbcomp = (a[:dbname] <=> b[:dbname])
      if ! dbcomp.zero? then
        retval = dbcomp
      else
        accomp = (a[:accession] <=> b[:accession])
        if ! accomp.zero? then
          retval = accomp
        else
          a[:version] = '' if a[:version].nil?
          b[:version] = '' if b[:version].nil?
          retval = (a[:version] <=> b[:version])
        end
      end
      retval
    }
    return sorted_dbxrefs
  end # get_dbxrefs
  
  def get_cvterms
    # sort cvterms by cvname => name => is obsolete
    sorted_cvterms = @stream_parser.all_cvterms.sort{|a,b|
      retval = 0
       cvcomp = (a[:cvname] <=> b[:cvname])
      if ! cvcomp.zero? then
        retval = cvcomp
      else
        namecomp = (a[:name] <=> b[:name])
        if ! namecomp.zero? then
          retval = namecomp
        else
          retval = (a[:is_obsolete] <=> b[:is_obsolete])
        end
      end
      retval
    } 
    return sorted_cvterms
  end # get_cvterms

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
    # FIXME -- is there a better way to get a path to the template file?
    chadoxml_template_fullpath = "/var/www/pipeline/submit/app/views/pipeline/chadoxml_patch_template.chadoxml.erb"
    chadoxml_template = File.open(chadoxml_template_fullpath, 'r'){|f| f.read }
    erb_renderer = ERB.new(chadoxml_template)
    chadoxml_string = erb_renderer.result(binding)

    patchfile_path = File.join(@xml_path, get_next_patch_filename()) 
    write_patchfile = File.open(patchfile_path, 'w'){|wpf| wpf.write(chadoxml_string)}

  return chadoxml_string
  end # make_patch_file

  def get_patch_filenames
    all_files = Dir.entries(@xml_path)
    patch_files = all_files.select{|f| f =~ /^patch_\d+_#{@project.id}\.chadoxml$/}
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
        pf.gsub!(/_#{@project.id}\.chadoxml/, "")
      }
      patch_files.map!{|pf| pf.to_i}
      patch_files.sort!
      
      # find next number not on list
      next_patch_number =  patch_files.last + 1 
    end
    # construct filename & return
    return "patch_#{next_patch_number}_#{@project.id}.chadoxml"
  end # get_next_patch_filename

  # Sorts out the checkmarks for inserting patches into the DB & deleting them
  def insertDB_and_delete(params)
    props_to_add = []
    props_to_delete = []
    result = ""
    params.each{|key, val|
      # if it matches add, add it to the DB
      if key =~ /^add_patch_\d+_#{@project.id}\.chadoxml$/ then
       result += add_patch_to_db(key.gsub(/add_/, ""))
      # if it matches delete, delete the file
      elsif key =~ /^delete_patch_\d+_#{@project.id}\.chadoxml$/ then
        result += delete_patchfile(key.gsub(/delete_/, ""))
      end
    }
    return result
  end #insertDB_and_delete
  
  def add_patch_to_db(patch_filename)
    full_patch_path = File.join(@xml_path, patch_filename)

    # Construct the command to add the patch to the DB

    loader =  "perl -I /var/www/pipeline/submit/script/loaders/modencode " +
    "/var/www/pipeline/submit/script/loaders/modencode/stag-storenode.pl "
    
    params = "-d=\"dbi:Pg:dbname=test2;host=localhost\" " +
            "-password=ir84#4nm -user=db_public "

    schema = "-s \"modencode_experiment_#{@project.id}\" "
    
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
    unless File.exists?(@master_xmlfile) then
     File.open(@master_xmlfile, "w"){|mxf| mxf.puts "<chadoxml>\n</chadoxml>" }
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
    File.open(@master_xmlfile, "r+"){|mxf|
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
    File.open(@master_xmlfile, "w"){|mxf|
      mxf.puts master_with_new
    } 

  end # add_to_master


  def delete_patchfile(patch_filename)
    full_patch_path = File.join(@xml_path, patch_filename)
    begin
      File.delete(full_patch_path)
    rescue
      return "Error in deleting #{full_patch_path}: #{$!}\n"
    end
      return "Deleted patchfile #{patch_filename}\n"
  end #delete_patchfile

end
