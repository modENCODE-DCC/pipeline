#!/usr/bin/ruby
# This file implements an REXML Stream Parser for extracting certain
# properties from ChadoXML files.
# It is used by the add_experiment_prop controller .

# To populate the lists which are publicly-visible, 
# parse_file must be called after initialization.
class ChadoXMLListener
  
  # Which elements to listen to
  def initialize(filepath)
    @base_xml = File.open(filepath).read

    # The arrays of things found we'd like populated
    # once the file has finished parsing!
    
    # element = experiment's uniquename
    @all_experiments = []
    # element = {:dbname => dbname, :accession => acc, :version => ver}
    # This will only include dbxrefs that are found attached to experiment_props
    @all_dbxrefs = []
    # @pending_dbxrefs in the format "id" => {dbxref}
    @pending_dbxrefs = {} # Actually all dbxrefs, but don't export non-expprop ones
      
    # element = {:cvname => cvname, :name => cvt, :is_obsolete =>iob}
    @all_cvterms = []

    # All CVs and DBs found for constructing dbxrefs, cvterms
    # each element in the format :id => "name"
    @all_cvs = {}
    @all_dbs = {}

    # tag_stack
    # the depth of tags we are in right now
    @tag_stack = []
  
    # Constructing the elements of @all_dbxrefs and @all_cvterms
    @current_dbxref = {}
    @current_cvterm = {}
    @current_dbxref_id = ""
    # stores the id for cv and db so we can connect it to the name
    @current_cv = {}
    @current_db = {}
  end # initialize

  attr_accessor :all_dbxrefs, :all_cvterms, :all_experiments

  def parse_file
    REXML::Document.parse_stream(@base_xml, self)

    return {
      :dbxrefs => @all_dbxrefs,
      :cvterms => @all_cvterms,
      :experiments => @all_experiments
    }
  end

  def tag_start(name, attributes)
    @tag_stack.push(name)
    case name
      when "cv" # get the ID and remember it for the text!
        @current_cv[:id] = attributes['id']
      when "db" 
        @current_db[:id] = attributes['id']
      when "dbxref"
        @current_dbxref_id = attributes['id']
    end
  
  end #tag_start

  def tag_end(name)
    lasttag = @tag_stack.pop
    if lasttag != name then
      raise Exception "The stream parser's stack is inconsistent with the XML!"
      # Weird! the stack has been corrupted!
    end

    case name
      when "dbxref" # save the completed dbxref
        # if it was declared in an experiment_prop, stick it right on
        if @tag_stack.include? "experiment_prop" then
          @all_dbxrefs.push(@current_dbxref)
        else
          # Put the dbxref on the temp array
          @pending_dbxrefs[@current_dbxref_id] = @current_dbxref
        end
        @current_dbxref = {}
        @current_dbxref_id = ""
       when "cvterm"
        @all_cvterms.push(@current_cvterm)
        @current_cvterm = {}
     end

  end #tag_end

  def text(text_in)
    # Watch for text that I am interested in!
    return unless text_in =~ /\S/ # whitespace is not interesting
    case @tag_stack.last(2)
      when ["experiment", "uniquename"]
        @all_experiments.push(text_in)
      when ["experiment_prop", "dbxref_id"]
        # If we've got a dbxref attached to an experiment_prop,
        # move it to the finalized dbxref list
        # and remove it from the pending list 
        # If it's not there, it was probably added already
        @all_dbxrefs.push( @pending_dbxrefs.delete(text_in) ) unless @pending_dbxrefs[text_in].nil?

      when ["dbxref", "accession"]
        @current_dbxref[:accession] = text_in
      when ["dbxref", "version"]
        @current_dbxref[:version] = text_in
      when ["dbxref", "db_id"] 
       if text_in =~ /\S/ then 
          # when db_id has text in it, it's a reference to an earlier
          # DB ... so pull it out of the @all_dbs
          # make sure it's actually text & not just wacky whitespace
          @current_dbxref[:dbname] = @all_dbs[text_in]
        end
      when ["db", "name"]
        # it's a new db -- add it to the list of dbs by its ID
        # and add it to its dbxref
        @all_dbs[@current_db[:id]] = text_in
        @current_dbxref[:dbname] = text_in
      when ["cvterm", "name"]
        @current_cvterm[:name] = text_in
      when ["cvterm", "is_obsolete"]
        @current_cvterm[:is_obsolete] = text_in
      when ["cvterm", "cv_id"]
        if text_in =~ /\S/ then 
        @current_cvterm[:cvname] = @all_cvs[text_in]
        end
      when ["cv", "name"] # it's a new cv -- @current_cv should have the id
        @all_cvs[@current_cv[:id]] = text_in
        @current_cvterm[:cvname] = text_in
      else
   end
  
  end #text

  

  def method_missing
    # do nothing. Probably won't ever get called
  end

end #ChadoXMLListener
