class ValidateIdf2chadoxml < Validate
  def formatted_status
    formatted_string = '<table style="padding: 0px; margin: 0px; border-collapse: collapse;" cellspacing="0" border="0">'
    self.stderr.each do |line|
      if line !~ /^[A-Z]+:/ then
        line = '<tr><th>&nbsp;</th><td style="vertical-align:top">' + line + '</td></tr>'
      else
        (level, message) = line.split(":", 2)
        indent = message.match(/^ */)[0].length
        message.gsub!(/^ */, '')
        href = message.clone
        href.sub!(/^(Error|Warning): /, '')
        error_description = ERROR_MESSAGES.find { |regex| href =~ regex[0] }
        if error_description then
          message = "<a style=\"cursor: help; color: #000088\" href=\"http://wiki.modencode.org/project/index.php/#{error_description[1]}\">#{message}</a>"
        end
        
        case level.upcase
        when "NOTICE" then
          line = "<tr><th style=\"vertical-align: top; padding-top: 3px; color: black; font-weight: bold\">#{level.upcase}</th><td style=\"vertical-align: top; padding-top: 3px; padding-left: #{indent*3}px;\">#{message}</td></tr>"
        when "WARNING" then
          line = "<tr><th style=\"vertical-align: top; padding-top: 3px; color: orange; font-weight: bold\">#{level.upcase}</th><td style=\"vertical-align: top; padding-top: 3px; padding-left: #{indent*3}px;\">#{message}</td></tr>"
        when "ERROR" then
          line = "<tr><th style=\"vertical-align: top; padding-top: 3px; color: red; font-weight: bold\">#{level.upcase}</th><td style=\"vertical-align: top; padding-top: 3px; padding-left: #{indent*3}px;\">#{message}</td></tr>"
        else
          line = "<tr><th style=\"vertical-align: top; padding-top: 3px; color: black; font-weight: normal\">#{level.upcase}</th><td style=\"vertical-align: top; padding-top: 3px; padding-left: #{indent*3}px;\">#{message}</td></tr>"
        end
      end

      formatted_string << line << "\n"
    end
    formatted_string + "</table>"
  end
  def short_formatted_status
    formatted_string = '<table style="padding: 0px; margin: 0px; border-collapse: collapse;" cellspacing="0" border="0">'

    # Get at least two lines (from the end of the log) that start with NOTICE/WARNING/ERROR/etc.
    lines = Array.new
    self.stderr.split($/).reverse.each do |line|
      lines.unshift line
      break if lines.find_all { |l| l =~ /^[A-Z]+:/ }.size >= 2
    end

    lines.each do |line|
      if line !~ /^[A-Z]+:/ then
        line = '<tr><th>&nbsp;</th><td style="vertical-align:top">' + line + '</td></tr>'
      else
        (level, message) = line.split(":", 2)
        indent = message.match(/^ */)[0].length
        message.gsub!(/^ */, '')
        case level.upcase
        when "NOTICE" then
          line = "<tr><th style=\"vertical-align: top; padding-top: 1px; color: black; font-weight: bold\">#{level.upcase}</th><td style=\"vertical-align: top; padding-top: 1px; padding-left: #{indent*3}px;\">#{message}</td></tr>"
        when "WARNING" then
          line = "<tr><th style=\"vertical-align: top; padding-top: 1px; color: orange; font-weight: bold\">#{level.upcase}</th><td style=\"vertical-align: top; padding-top: 1px; padding-left: #{indent*3}px;\">#{message}</td></tr>"
        when "ERROR" then
          line = "<tr><th style=\"vertical-align: top; padding-top: 1px; color: red; font-weight: bold\">#{level.upcase}</th><td style=\"vertical-align: top; padding-top: 1px; padding-left: #{indent*3}px;\">#{message}</td></tr>"
        else
          line = "<tr><th style=\"vertical-align: top; padding-top: 1px; color: black; font-weight: normal\">#{level.upcase}</th><td style=\"vertical-align: top; padding-top: 1px; padding-left: #{indent*3}px;\">#{message}</td></tr>"
        end
      end

      formatted_string << line << "\n"
    end
    formatted_string + "</table>"
  end

  ERROR_MESSAGES = [
[ /^Adding types from the wiki to input and output parameters\.$/, "Adding types from the wiki to input and output parameters" ],
[ /^Adding wiki protocol metadata to the protocol objects\.$/, "Adding wiki protocol metadata to the protocol objects" ],
[ /^A (\S*) cannot mimic a (\S*)$/, "A ClassA cannot mimic a ClassB" ],
[ /^Attempting to write a feature_relationship with a subject but no object or vice versa.$/, "Attempting to write a feature_relationship with a subject but no object or vice versa" ],
[ /^BED file (.*) does not seem valid beginning at line (\d*):$/, "BED file BED_File does not seem valid beginning at line Line_Number" ],
[ /^Cannot find BED file (.*) for column (.*)$/, "Cannot find BED file BED_File for column Column_Heading" ],
[ /^Cannot find the '(.*)' ontology, so accession (.*) is not valid\.$/, "Cannot find the 'CV' ontology, so accession Accession is not valid" ],
[ /^Cannot find the '(.*)' ontology, so '(.*)' is not valid\.$/, "Cannot find the 'CV' ontology, so 'Term' is not valid" ],
[ /^Cannot find the Term Source REF definition for (.*) in the IDF, although it is referenced in the SDRF\.$/, "Cannot find the Term Source REF definition for Term_Source_REF in the IDF, although it is referenced in the SDRF" ],
[ /^Cannot have more than one un-named input parameter \((.*)\) for protocol (.*) in the SDRF\.$/, "Cannot have more than one un-named input parameter (Input_Parameters) for protocol Protocol_Name in the SDRF" ],
[ /^Cannot have more than one un-named input parameter \((.*)\) for protocol (.*) in the wiki\.$/, "Cannot have more than one un-named input parameter (Input_Parameters) for protocol Protocol_Name in the wiki" ],
[ /^Cannot have more than one un-named output parameter \((.*)\) for protocol (.*) in the SDRF\.$/, "Cannot have more than one un-named output parameter (Output_Parameters) for protocol Protocol_Name in the SDRF" ],
[ /^Cannot have more than one un-named output parameter \((.*)\) for protocol '(.*)' in the wiki\.$/, "Cannot have more than one un-named output parameter (Output_Parameters) for protocol 'Protocol_Name' in the wiki" ],

[ /^Cannot open EST list file '(.*)' for reading\.$/, "Cannot open EST list file 'EST_File' for reading" ],
[ /^Cannot open GFF file '(.*)' for reading\.$/, "Cannot open GFF file 'GFF_File' for reading" ],
[ /^Cannot parse OBO file '(.*)' using (.*)$/, "Cannot parse OBO file 'OBO_File' using OBO_Parser" ],
[ /^Cannot print_tsv a \@columns array that is not an array of arrays$/, "Cannot print_tsv a \@columns array that is not an array of arrays" ],
[ /^Cannot print_tsv a \@columns array that is not a rectangular array of arrays(.*)$/, "Cannot print_tsv a \@columns array that is not a rectangular array of arrays" ],
[ /^Cannot read EST list file '(.*)'\.$/, "Cannot read EST list file 'EST_List_File'" ],

[ /^Cannot read GFF file '(.*)'\.$/, "Cannot read GFF file 'GFF_File'" ],
[ /^Can't add synonym '(.*)' for missing CV identified by (.*)$/, "Can't add synonym 'Synonym' for missing CV identified by URL" ],
[ /^Can't fetch or check age of canonical CV source file for '(.*)' at url '(.*)'(.*)$/, "Can't fetch or check age of canonical CV source file for 'CV' at url 'URL'" ],
[ /^Can't find accession for (.*):(.*)$/, "Can't find accession for CV:Term" ],
[ /^Can't find a modENCODE project group matching '(.*)'(.*)\.$/, "Can't find a modENCODE project group matching 'Group'" ],
[ /^Can't find a modENCODE project subgroup of (.*) named '(.*)'. Options are: (.*)\.$/, :Options, "Can't find a modENCODE project subgroup of Group named 'Subgroup'" ],

[ /^Can't find any modENCODE project group - should be defined in the IDF\.$/, "Can't find any modENCODE project group - should be defined in the IDF" ],
[ /^Can't find file '(.*)'$/, "Can't find file 'Document'" ],
[ /^Can't find Result File [(.*)]=(.*)\.$/, "Can't find Result File [Heading]=File" ],
[ /^Can't find SDRF file (.*)\.$/, "Can't find SDRF file SDRF_File" ],
[ /^Can't find the input [(.*)] in the SDRF for protocol '(.*)'\.$/, "Can't find the input [Input] in the SDRF for protocol 'Protocol'" ],
[ /^Can't find the output [(.*)] in the SDRF for protocol '(.*)'\.$/, "Can't find the output [Output] in the SDRF for protocol 'Protocol'" ],

[ /^Can't get an accession for a CV of type URL_DBFields. Assuming term and accession are the same\.$/, "Can't get an accession for a CV of type URL_DBFields. Assuming term and accession are the same" ],
[ /^Can't get the prepared query '(.*)' with no database connection\.$/, "Can't get the prepared query 'Query' with no database connection" ],
[ /^Can't parse OWL files yet, sorry. Please update your IDF to point to an OBO file\.$/, "Can't parse OWL files yet, sorry. Please update your IDF to point to an OBO file" ],
[ /^Can't validate all ESTs\. There is\/are (.*) EST\(s\) that could not be validated\. See previous errors\.$/, "Can't validate all ESTs" ],
[ /^Can't validate all traces\. There is\/are (.*) trace(s) that could not be validated\. See previous errors\.$/, "Can't validate all traces" ],
[ /^Could not find a canonical URL for the controlled vocabulary (.*) when validating term (.*)\.$/, "Could not find a canonical URL for the controlled vocabulary CV when validating term Term" ],
[ /^Could not find the protocol type (.*):(.*) defined in the wiki for '(.*)'\.$/, "Could not find the protocol type CV:Term defined in the wiki for 'Protocol'" ],

[ /^Could not parse '(.*)' as a date in format YYYY-MM-DD for the Date of Experiment. Please correct your IDF\.$/, "Could not parse 'Date' as a date in format YYYY-MM-DD for the Date of Experiment. Please correct your IDF" ],
[ /^Could not parse '(.*)' as a date in format YYYY-MM-DD for the Public Release Date. Please correct your IDF\.$/, "Could not parse 'Release_Date' as a date in format YYYY-MM-DD for the Public Release Date. Please correct your IDF" ],
[ /^Couldn't add the termsource specified by '(.*)' \((.*)\)\.$/, "Couldn't add the termsource specified by 'DB' (Name)" ],
[ /^Couldn't connect to canonical URL source \((.*)\)(.*)$/, "Couldn't connect to canonical URL source (URL)" ],
[ /^Couldn't connect to data source "(.*)", using username "(.*)" and password "(.*)"(.*)$/, "Couldn't connect to data source \"DSN\", using username \"Username\" and password \"Password\"" ],
[ /^Couldn't connect to TRACE server$/, "Couldn't connect to TRACE server" ],
[ /^Couldn't expand (.*) in the (.*) \[(.*)\] field into a new set of attribute columns in the (.*) validator\.$/, "Couldn't expand Attribute_Value in the Attribute_Heading [Attribute_Name] field into a new set of attribute columns in the Validator validator" ],

[ /^Couldn't expand (.*) in the (.*) \[(.*)\] field with any attribute columns in the (.*) validator\.$/, "Couldn't expand Value in the Datum [Name] field with any attribute columns in the Validator validator" ],
[ /^Couldn't expand the empty value in the (.*) \[(.*)\] field into a new set of attribute columns in the (.*) validator\.$/, "Couldn't expand the empty value in the Value [Attribute] field into a new set of attribute columns in the Validator validator" ],
[ /^Couldn't expand the empty value in the (.*) \[(.*)\] field with any attribute columns in the (.*) validator\.$/, "Couldn't expand the empty value in the Datum [Name] field with any attribute columns in the Validator validator" ],
[ /^Couldn't fetch canonical source file '(.*)', and no cached copy found\.$/, "Couldn't fetch canonical source file 'URL', and no cached copy found" ],
[ /^Couldn't fetch ESTs by primary ID; got response "(.*)" from NCBI\. Retrying\.$/, "Couldn't fetch ESTs by primary ID; got response \"Response\" from NCBI\. Retrying" ],
[ /^Couldn't find any ESTs using when fetching for '(.*)' at NCBI\.$/, "Couldn't find any ESTs using when fetching for 'Term' at NCBI" ],
[ /^Couldn't find any ESTs using when searching for '(.*)' at NCBI\.$/, "Couldn't find any ESTs using when searching for 'Term' at NCBI" ],

[ /^Couldn't find cvterm '(.*)\.(.*)'\.$/, "Couldn't find cvterm 'CV:Term'" ],
[ /^Couldn't find the accession (.*) in '(.*)' \((.*)\)\.$/, "Couldn't find the accession Accession in 'DB' (URL)" ],
[ /^Couldn't find the EST identified by '(.*)' in search results from NCBI\.$/, "Couldn't find the EST identified by 'EST_Accession' in search results from NCBI" ],
[ /^Couldn't find the term (.*) in '(.*)' \((.*)\)\.$/, "Couldn't find the term Term in 'DB' (URL)" ],

[ /^Couldn't find the Trace identified by (.*) in search results from NCBI\.$/, "Couldn't find the Trace identified by Trace_ID in search results from NCBI" ],
[ /^Couldn't get a feature object for supposed transcript (.*)\.$/, "Couldn't get a feature object for supposed transcript Transcript_ID" ],
[ /^Couldn't get a search cookie when searching for ESTs; got an unexpected response from NCBI\. Retrying\.$/, "Couldn't get a search cookie when searching for ESTs; got an unexpected response from NCBI" ],
[ /^Couldn't parse header line of SDRF\.$/, "Couldn't parse header line of SDRF" ],
[ /^Couldn't parse organism genus and species out of (.*) \[(.*)\]=(.*)\.$/, "Couldn't parse organism genus and species out of Attribute [Name]=Value" ],

[ /^Couldn't read file (.*)$/, "Couldn't read file File" ],
[ /^Couldn't read SDRF file (.*)\.$/, "Couldn't read SDRF file SDRF_File" ],
[ /^Couldn't retrieve EST by ID; got an unknown response from NCBI\. Retrying\.$/, "Couldn't retrieve EST by ID; got an unknown response from NCBI" ],
[ /^Couldn't retrieve Traces by ID; got an unknown response from TA\. Retrying\.$/, "Couldn't retrieve Traces by ID; got an unknown response from TA" ],
[ /^Couldn't search for EST ID's; got response "(.*)" from NCBI\. Retrying\.$/, "Couldn't search for EST ID's; got response \"Error_Message\" from NCBI" ],

[ /^Couldn't tell if URL (.*) was valid\. Retrying\.$/, "Couldn't tell if URL URL was valid" ],
[ /^Didn't process input line fully: (.*)$/, "Didn't process input line fully" ],
[ /^Don't know how to parse the CV at URL: '(.*)' of type: '(.*)'\.$/, "Don't know how to parse the CV at URL: 'URL' of type: 'URL_Type'" ],
[ /^Each term in Protocol Type must have a prefix if there is more than one term source \(e\.g\. MO:grow, SO:gene\)\.$/, "Each term in Protocol Type must have a prefix if there is more than one term source \(e\.g\. MO:grow, SO:gene\)" ],
[ /^Each term in Protocol Type REALLY SHOULD have a prefix if there is more than one type, even if there is only one term source ref \(e\.g\. (.*):(.*)\)\.$/, "Each term in Protocol Type REALLY SHOULD have a prefix if there is more than one type, even if there is only one term source ref (e.g. CV:Name)" ],
[ /^Experiment is empty; perhaps you need to call load_experiment(\$experiment_id) first\?$/, "Experiment is empty; perhaps you need to call load_experiment(\$experiment_id) first\?" ],

[ /^Falling back to fetching remaining (.*) ESTs from FlyBase(\.\.\.)$/, "Falling back to fetching remaining Number_Of_ESTs ESTs from FlyBase" ],
[ /^Falling back to pulling down EST information from Genbank by primary ID(\.\.\.)$/, "Falling back to pulling down EST information from Genbank by primary ID" ],
[ /^Falling back to pulling down EST information from Genbank by searching(\.\.\.)$/, "Falling back to pulling down EST information from Genbank by searching" ],
[ /^Fetching ESTs from (.*) to (.*)\.$/, "Fetching ESTs from First_EST to Last_EST" ],
[ /^Fetching expanded attributes for data from the wiki(\.\.\.)$/, "Fetching expanded attributes for data from the wiki" ],
[ /^Fetching expanded attributes from the wiki(\.\.\.)$/, "Fetching expanded attributes from the wiki" ],

[ /^Fetching feature (.*), (.*) of (.*)\.$/, "Fetching feature Feature_ID, Feature_Number of Total_Features" ],
[ /^Fetching protocol definitions from the wiki(\.\.\.)$/, "Fetching protocol definitions from the wiki" ],
[ /^Fetching (.*) ESTs from local modENCODE database(\.\.\.)$/, "Fetching Number_Of_ESTs ESTs from local modENCODE database" ],
[ /^Fetching (.*) Traces from local modENCODE database(\.\.\.)$/, "Fetching Number_Of_Traces Traces from local modENCODE database" ],
[ /^Fetching Traces from (.*) to (.*)(\.\.\.)$/, "Fetching Traces from First_Trace to Last_Trace" ],
[ /^Found a putative URL type \((.*)\) but not a URL \((.*)\) for controlled vocabulary (.*)\. Assuming this is a CV we're not meant to check\.$/, "Found a putative URL type (URL_Type) but not a URL (URL) for controlled vocabulary CV. Assuming this is a CV we're not meant to check" ],

[ /^Found a URL \((.*)\) but not a URL type \((.*)\), for controlled vocabulary (.*)\. Please check DBFieldsConf\.php$/, "Found a URL (URL) but not a URL type (URL_Type), for controlled vocabulary CV. Please check DBFieldsConf.php" ],
[ /^Found more than one feature '(.*)' with type (.*)\.$/, "Found more than one feature 'Feature' with type Type" ],
[ /^Given a termsource to validate with no term or accession; testing accession built into termsource: (.*)$/, "Given a termsource to validate with no term or accession; testing accession built into termsource: Term_Source" ],
[ /^Got back (.*) applied_protocols when (.*) applied_protocols were expected\.$/, "Got back Number_Of_Found_Protocols applied_protocols when Number_Of_Expected_Protocols applied_protocols were expected" ],
[ /^input term '(.*)' is named in the IDF\/SDRF, but not in the wiki\.$/, "input term 'Input_Term' is named in the IDF\/SDRF, but not in the wiki" ],
[ /^Loading transcripts from database\.$/, "Loading transcripts from database" ],
[ /^Make sure all types and term sources are valid\.$/, "Make sure all types and term sources are valid" ],

[ /^Making sure that all CV and DB names are consistent\.$/, "Making sure that all CV and DB names are consistent" ],
[ /^Merging data elements into experiment object\.$/, "Merging data elements into experiment object" ],
[ /^Mismatch between feature locations in GFF files with the same IDs for ID=(.*)\.$/, "Mismatch between feature locations in GFF files with the same IDs for ID=GFF_ID" ],
[ /^No BED file for (.*)$/, "No BED file for Data_Column" ],
[ /^No Date of Experiment provided in the IDF, assuming current date(.*)\.$/, "No Date of Experiment provided in the IDF, assuming current date" ],
[ /^No description for protocol (.*) found at (.*)\. Using URL as description\.$/, "No description for protocol Protocol_Name found at Protocol_URL. Using URL as description" ],
[ /^No modENCODE project sub-group defined - defaulting to main group '(.*)'\.$/, "No modENCODE project sub-group defined - defaulting to main group 'Group_Name'" ],
[ /^No Public Release Date provided in the IDF, assuming current date(.*)\.$/, "No Public Release Date provided in the IDF, assuming current date" ],

[ /^Nothing to validate; no term or accession given, and no accession built into termsource: (.*)$/, "Nothing to validate; no term or accession given, and no accession built into termsource: Term_Source" ],
[ /^No validator for attribute (.*) \[(.*)] with term source type (.*)\.$/, "No validator for attribute Attribute [Name] with term source type Term_Source_Type" ],
[ /^No validator for attribute of type (.*)\.$/, "No validator for attribute of type Attribute_Type." ],
[ /^No validator for data type (.*)\.$/, "No validator for data type Data_Type." ],
[ /^Oh no, terrible things have happened\.$/, "Unknown Error" ],
[ /^output term '(.*)' is named in the IDF\/SDRF, but not in the wiki\.$/, "output term 'Output_Term' is named in the IDF/SDRF, but not in the wiki" ],
[ /^Parsed line (.*)\.$/, "Parsed line Line_Number" ],

[ /^Parsed (.*) trace records$/, "Parsed Number_Of_Traces trace records" ],
[ /^Parsing attached GFF3 files\.$/, "Parsing attached GFF3 files" ],
[ /^\(Parsing (.*)\.\.\./, "Parsing CV" ],
[ /^Parsing GFF file (.*)\.\.\.$/, "Parsing GFF file GFF_File" ],
[ /^Parsing list of ESTs from file (.*)\.$/, "Parsing list of ESTs from file EST_List_File" ],
[ /^Parsing list of ESTs\.$/, "Parsing list of ESTs" ],
[ /^Parsing SDRF '(.*)'\.$/, "Parsing SDRF 'SDRF_File'" ],
[ /^Protocol '(.*)' has no protocol type definition in the IDF\.$/, "Protocol 'Protocol' has no protocol type definition in the IDF" ],

[ /^Protocol slots are empty; perhaps you need to call load_experiment(\$experiment_id) first\?$/, "Protocol slots are empty; perhaps you need to call load_experiment(\$experiment_id) first\?" ],
[ /^Pulling down Trace information from Trace Archive by ID in batches of 200\.\.\.$/, "Pulling down Trace information from Trace Archive by ID in batches of 200" ],
[ /^Reading file\.\.\.$/, "Reading file" ],
[ /^Relationship between '(.*) and (.*)' doesn't have a valid CVTerm type '(.*)'$/, "Relationship between 'FeatureA and FeatureB' doesn't have a valid CVTerm type 'Type'" ],
[ /^Removing datum '(.*)' as input from '(.*)'; not found in IDF's Protocol Parameters\.$/, "Removing datum 'Datum_Name' as input from 'Protocol'; not found in IDF's Protocol Parameters" ],
[ /^Removing temporary definitions for term sources that were referenced in the SDRF\.$/, "Removing temporary definitions for term sources that were referenced in the SDRF" ],
[ /^ Retrieved (.*) traces\. Validating\.\.\.$/, "Retrieved Number_Of_Traces traces" ],
[ /^\(Re\)validating experiment vs\. wiki:$/, "(Re)validating experiment vs. wiki" ],

[ /^Searching ESTs from (.*) to (.*)\.$/, "Searching ESTs from First_EST to Last_EST" ],
[ /^Setting experiment description from wiki\.$/, "Setting experiment description from wiki" ],
[ /^Term source '(.*)' \((.*)\) does not contain a definition for attribute '(.*)\[(.*)\]=(.*)' of datum '(.*) \[(.*)\]=(.*)' of protocol '(.*)'\.$/, "Term source 'DB' (URL) does not contain a definition for attribute 'Attribute[Name]=Value' of datum 'Datum [Name]=Value' of protocol 'Protocol'" ],
[ /^Term source '(.*)' \((.*)\) does not contain a definition for attribute '(.*)\[(.*)\]=(.*)' of protocol '(.*)'\.$/, "Term source 'DB' (URL) does not contain a definition for attribute 'Attribute[Name]=Value' of protocol 'Protocol'" ],
[ /^Termsource '(.*)' \((.*)\) is not a valid DBXref for attribute '(.*)\[(.*)\]=(.*)'$/, "Termsource 'DB' (URL) is not a valid DBXref for attribute 'Attribute[Name]=Value'" ],
[ /^Term source '(.*)' \((.*)\) does not contain a definition for datum '(.*) \[(.*)\]=(.*)' of protocol '(.*)'\.$/, "Term source 'DB' (URL) does not contain a definition for datum 'Datum [Name]=Value' of protocol 'Protocol'" ],

[ /^Termsource '(.*)' \((.*)\) is not a valid DBXref for datum '(.*)\[(.*)\]=(.*)'$/, "Termsource 'DB' (URL) is not a valid DBXref for datum 'Datum[Name]=Value'" ],
[ /^Termsource '(.*)' \((.*)\) is not a valid DBXref\.$/, "Termsource 'DB' (URL) is not a valid DBXref" ],
[ /^Termsource '(.*)' \((.*)\) is not a valid term source\/DBXref for experiment_prop '(.*)=(.*)'\.$/, "Termsource 'DB' (URL) is not a valid term source/DBXref for experiment_prop 'Experiment_Property=Value'" ],
[ /^Term source '(.*)' \((.*)\) does not contain a definition for protocol '(.*)'\.$/, "Term source 'DB' (URL) does not contain a definition for protocol 'Protocol'" ],
[ /^Termsource '(.*)' \((.*)\) is not a valid DBXref for protocol '(.*)'\.$/, "Termsource 'DB' (URL) is not a valid DBXref for protocol 'Protocol'" ],

[ /^The CV name (.*) is already used for (.*), but at attempt has been made to redefine it for (.*)\. Please check your IDF\.$/, "The CV name CV is already used for URL, but at attempt has been made to redefine it for New_URL. Please check your IDF" ],
[ /^The Date of Experiment '(.*)' was not in the format YYYY-MM-DD. It has been parsed as (.*), i.e. (.*)\.$/, "The Date of Experiment 'Input_Date' was not in the format YYYY-MM-DD. It has been parsed as Parsed_Date" ],
[ /^The following protocol\(s\) are referred to in the SDRF but not defined in the IDF!$/, "The following protocol(s) are referred to in the SDRF but not defined in the IDF" ],
[ /^The following term source\(s\) are referred to in the SDRF but not defined in the IDF!$/, "The following term source(s) are referred to in the SDRF but not defined in the IDF" ],

[ /^The Investigation Title field is missing from the IDF\.$/, "The Investigation Title field is missing from the IDF" ],
[ /^The protocol '(.*)' has (.*) Protocol Types in the wiki, and (.*) in the IDF\.$/, "The protocol 'Protocol' has Number_Of_Wiki_Protocol_Types Protocol Types in the wiki, and Number_Of_IDF_Protocol_Types in the IDF" ],
[ /^The Protocol Type field for (.*) is missing from the IDF\.$/, "The Protocol Type field for Protocol is missing from the IDF" ],
[ /^The Protocol \(Type\) Term Source REF field for (.*) is missing from the IDF\.$/, "The Protocol Term Source REF field for Protocol is missing from the IDF" ],
[ /^The Public Release Date '(.*)' was not in the format YYYY-MM-DD. It has been parsed as (.*), i.e. (.*)\.$/, "The Public Release Date 'Input_Date' was not in the format YYYY-MM-DD. It has been parsed as Parsed_Date" ],

[ /^There are (.*) input parameters according to the wiki/, "There are Number_Of_Input_Parameters input parameters according to the wiki" ],
[ /^There are (.*) output parameters according to the wiki/, "There are Number_Of_Output_Parameters input parameters according to the wiki" ],
[ /^The sequence region feature (.*) does not have an associated organism. This may be okay, as long as the feature already exists in the database\.$/, "The sequence region feature Sequence_Region_Feature does not have an associated organism" ],
[ /^The term source (.*) for Protocol Type '(.*)' is not mentioned in the Protocol Term Source REF field\.$/, "The term source CV for Protocol Type 'Protocol_Type' is not mentioned in the Protocol Term Source REF field" ],
[ /^Type '(.*):(.*)' is not a valid CVTerm for attribute '(.*)\[(.*)\]=(.*)'$/, "Type 'CV:Term' is not a valid CVTerm for attribute 'Attribute[Name]=Value'" ],

[ /^Type '(.*):(.*)' is not a valid CVTerm\.$/, "Type 'CV:Term' is not a valid CVTerm" ],
[ /^Type '(.*):(.*)' is not a valid CVTerm for datum '(.*)\[(.*)\]=(.*)'\.$/, "Type 'CV:Term' is not a valid CVTerm for datum 'Datum[Name]=Value'" ],
[ /^Type '(.*):(.*)' is not a valid CVTerm for experiment_prop '(.*)=(.*)'\.$/, "Type 'CV:Term' is not a valid CVTerm for experiment_prop 'Experiment_Property=Value'" ],
[ /^Type '(.*):(.*)' is not a valid CVTerm for feature '(.*)'$/, "Type 'CV:Term' is not a valid CVTerm for feature 'Feature'" ],
[ /^Unable to find accession for (.*) in (.*)$/, "Unable to find accession for Term in CV" ],

[ /^Unable to find the '(.*)' field in the SDRF even though it is defined in the IDF\.$/, "Unable to find the 'IDF_Input_Param' field in the SDRF even though it is defined in the IDF" ],
[ /^Unable to use a '(.*)' as a ModENCODE::ErrorHandler logger as it does not subclass ModENCODE::ErrorHandler\. Reverting to default\.$/, "Unable to use a 'Logger' as a ModENCODE::ErrorHandler logger as it does not subclass ModENCODE::ErrorHandler\. Reverting to default" ],
[ /^Using cached copy of CV for (.*); no change on server\.$/, "Using cached copy of CV for CV; no change on server" ],

[ /^Using cached\.$/, "Using cached" ],
[ /^Validating attributes of type organism\.$/, "Validating attributes of type organism" ],
[ /^Validating (.*) ESTs\.\.\.$/, "Validating Number_Of_ESTs ESTs" ],
[ /^Validating (.*) Traces\.\.\.$/, "Validating Number_Of_Traces Traces" ],
[ /^Validating term sources and term source references\.$/, "Validating term sources and term source references" ],

[ /^Validating types and controlled vocabularies\.$/, "Validating types and controlled vocabularies" ],
[ /^Validating wiki CV terms\.\.\.$/, "Validating wiki CV terms" ],
[ /^Verifying IDF protocols against wiki\.\.\.$/, "Verifying IDF protocols against wiki" ],
[ /^Verifying term sources referenced in the SDRF against the terms they constrain\.$/, "Verifying term sources referenced in the SDRF against the terms they constrain" ],
[ /^Verifying that IDF controlled vocabulary match SDRF controlled vocabulary\.$/, "Verifying that IDF controlled vocabulary match SDRF controlled vocabulary" ],

[ /^Parsing IDF and SDRF\.\.\.$/, "Parsing IDF and SDRF" ],
[ /^Unable to parse IDF\. Terminating\.$/, "Unable to parse IDF\. Terminating" ],
[ /^Validating IDF vs SDRF\.\.\.$/, "Validating IDF vs SDRF" ],
[ /^Validating presence of valid ModENCODE project\/subproject names\.\.\.$/, "Validating presence of valid ModENCODE project/subproject names" ],
[ /^Refusing to continue validation without valid project\/subproject names\.$/, "Refusing to continue validation without valid project/subproject names" ],
[ /^Validating presence of valid public release and generation dates\.\.\.$/, "Validating presence of valid public release and generation dates" ],

[ /^Refusing to continue validation without valid public release or data generation dates\.$/, "Refusing to continue validation without valid public release or data generation dates" ],
[ /^Validating IDF and SDRF vs wiki\.\.\.$/, "Validating IDF and SDRF vs wiki" ],
[ /^Merging wiki data into experiment\.\.\.$/, "Merging wiki data into experiment" ],
[ /^Expanding attribute columns\.$/, "Expanding attribute columns" ],
[ /^Reading data files\.$/, "Reading data files" ],
[ /^Couldn't validate data columns!$/, "Couldn't validate data columns" ],

[ /^Validating term sources \(DBXrefs\) against known ontologies\.$/, "Validating term sources (DBXrefs) against known ontologies" ],
[ /^Merging missing accessions and\/or term names from known ontologies\.$/, "Merging missing accessions and/or term names from known ontologies" ],
[ /^Couldn't validate term sources and types!$/, "Couldn't validate term sources and types" ],
[ /^Cannot write experiment to file (.*), defaulting to STDOUT\./, "Cannot write experiment to file Output_File, defaulting to STDOUT" ],
  ]
end
