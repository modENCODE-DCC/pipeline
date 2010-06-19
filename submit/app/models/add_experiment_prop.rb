class AddExperimentProp < Command
  module Status
    PARSING = "parsing ChadoXML"
    PARSED = "parsed ChadoXML"
    PARSING_FAILED = "parsing ChadoXML failed"
  end

  def controller
    @controller = AddExperimentPropController.new(:command => self) unless @controller
    @controller
  end
  def fail
    self.status = AddExperimentProp::Status::PARSING_FAILED
  end

  def discovered_xml_elements
    return Marshal.restore(Base64.decode64(self.stderr))
  end
  def discovered_xml_elements=(elements)
    self.stderr = Base64.encode64(Marshal.dump(elements))
  end

  def formatted_status
    # TODO: Put something pretty for output here
    "parsed?"
  end
  def short_formatted_status
    # TODO: Put something pretty for output here
    "parsed?"
  end

  # Returns a list of all experiments in the original xml file
  def get_experiments
   return self.discovered_xml_elements[:experiments]
  end # get_experiments

# Also get all the dbxrefs and cvterms so we can make dropdowns
# The stream parser's code makes assumptions about the structure of the xml file:
#   - All dbxrefs & cvterms are listed as direct children of <chadoxml>
#   - No macro (eg, <db>db_13</db>) appears earlier in the file than its
#       corresponding node
  
  def get_dbxrefs
    # Sort the dbxref by dbname => accession => version
    sorted_dbxrefs = self.discovered_xml_elements[:dbxrefs].sort{|a, b|
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
    sorted_cvterms = self.discovered_xml_elements[:cvterms].sort{|a,b|
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

  def status=(newstatus)
    write_attribute :status, newstatus
  end

end

