class ValidateIdf2chadoxml < Validate
  def formatted_status
    formatted_string = '<table style="padding: 0px; margin: 0px; border-collapse: collapse;" cellspacing="0" border="0">'
    if self.stderr then
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
            message = "<a style=\"cursor: help; color: #000088\" href=\"http://wiki.modencode.org/project/index.php/ValidatorErrors\##{error_description[1]}\">#{message}</a>"
          elsif (message !~ /^\s*Done(\.?)\s*$/)
            href_name = message.sub(/\s*$/, '').sub(/^\s*/, '').gsub(/'/, '.27').gsub(/"/, '.22').gsub(/\s/, '_').gsub(/,/, '.2C')
            message = "<a style=\"cursor: help; color: #000088\" href=\"http://wiki.modencode.org/project/index.php/ValidatorErrors\##{href_name}\">#{message}</a>"
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
    end
    formatted_string + "</table>"
  end
  def short_formatted_status
    formatted_string = '<table style="padding: 0px; margin: 0px; border-collapse: collapse;" cellspacing="0" border="0">'

    # Get at least two lines (from the end of the log) that start with NOTICE/WARNING/ERROR/etc.
    lines = Array.new
    if self.stderr then
      self.stderr.split($/).reverse.each do |line|
        lines.unshift line
        break if lines.find_all { |l| l =~ /^[A-Z]+:/ }.size >= 2
      end
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
    [ /^A (\S*) cannot mimic a (\S*)$/, "A_ClassA_cannot_mimic_a_ClassB" ],
    [ /^BED file (.*) does not seem valid beginning at line (\d*):$/, "BED_file_BED_File_does_not_seem_valid_beginning_at_line_Line_Number" ],
    [ /^Cannot find BED file (.*) for column (.*)$/, "Cannot_find_BED_file_BED_File_for_column_Column_Heading" ],
    [ /^Cannot find the '(.*)' ontology, so accession (.*) is not valid\.$/, "Cannot_find_the_.27CV.27_ontology.2C_so_accession_Accession_is_not_valid" ],
    [ /^Cannot find the '(.*)' ontology, so '(.*)' is not valid\.$/, "Cannot_find_the_.27CV.27_ontology.2C_so_.27Term.27_is_not_valid" ],
    [ /^Cannot find the Term Source REF definition for (.*) in the IDF, although it is referenced in the SDRF\.$/, "Cannot_find_the_Term_Source_REF_definition_for_Term_Source_REF_in_the_IDF.2C_although_it_is_referenced_in_the_SDRF" ],
    [ /^Cannot have more than one un-named input parameter \((.*)\) for protocol (.*) in the SDRF\.$/, "Cannot_have_more_than_one_un-named_input_parameter_(Input_Parameters)_for_protocol_Protocol_Name_in_the_SDRF" ],
    [ /^Cannot have more than one un-named input parameter \((.*)\) for protocol (.*) in the wiki\.$/, "Cannot_have_more_than_one_un-named_input_parameter_(Input_Parameters)_for_protocol_Protocol_Name_in_the_wiki" ],
    [ /^Cannot have more than one un-named output parameter \((.*)\) for protocol (.*) in the SDRF\.$/, "Cannot_have_more_than_one_un-named_output_parameter_(Output_Parameters)_for_protocol_Protocol_Name_in_the_SDRF" ],
    [ /^Cannot have more than one un-named output parameter \((.*)\) for protocol '(.*)' in the wiki\.$/, "Cannot_have_more_than_one_un-named_output_parameter_(Output_Parameters)_for_protocol_.27Protocol_Name.27_in_the_wiki" ],
    [ /^Cannot open EST list file '(.*)' for reading\.$/, "Cannot_open_EST_list_file_.27EST_File.27_for_reading" ],
    [ /^Cannot open GFF file '(.*)' for reading\.$/, "Cannot_open_GFF_file_.27GFF_File.27_for_reading" ],
    [ /^Cannot parse OBO file '(.*)' using (.*)$/, "Cannot_parse_OBO_file_.27OBO_File.27_using_OBO_Parser" ],
    [ /^Cannot print_tsv a \@columns array that is not a rectangular array of arrays(.*)$/, "Cannot_print_tsv_a_\@columns_array_that_is_not_a_rectangular_array_of_arrays" ],
    [ /^Cannot read EST list file '(.*)'\.$/, "Cannot_read_EST_list_file_.27EST_List_File.27" ],
    [ /^Cannot read GFF file '(.*)'\.$/, "Cannot_read_GFF_file_.27GFF_File.27" ],
    [ /^Can't add synonym '(.*)' for missing CV identified by (.*)$/, "Can.27t_add_synonym_.27Synonym.27_for_missing_CV_identified_by_URL" ],
    [ /^Can't fetch or check age of canonical CV source file for '(.*)' at url '(.*)'(.*)$/, "Can.27t_fetch_or_check_age_of_canonical_CV_source_file_for_.27CV.27_at_url_.27URL.27" ],
    [ /^Can't find accession for (.*):(.*)$/, "Can.27t_find_accession_for_CV:Term" ],
    [ /^Can't find a modENCODE project group matching '(.*)'(.*)\.$/, "Can.27t_find_a_modENCODE_project_group_matching_.27Group.27" ],
    [ /^Can't find a modENCODE project subgroup of (.*) named '(.*)'. Options are: (.*)\.$/, "Can.27t_find_a_modENCODE_project_subgroup_of_Group_named_.27Subgroup.27" ],
    [ /^Can't find file '(.*)'$/, "Can.27t_find_file_.27Document.27" ],
    [ /^Can't find Result File [(.*)]=(.*)\.$/, "Can.27t_find_Result_File_[Heading]=File" ],
    [ /^Can't find SDRF file (.*)\.$/, "Can.27t_find_SDRF_file_SDRF_File" ],
    [ /^Can't find the input [(.*)] in the SDRF for protocol '(.*)'\.$/, "Can.27t_find_the_input_[Input]_in_the_SDRF_for_protocol_.27Protocol.27" ],
    [ /^Can't find the output [(.*)] in the SDRF for protocol '(.*)'\.$/, "Can.27t_find_the_output_[Output]_in_the_SDRF_for_protocol_.27Protocol.27" ],
    [ /^Can't get the prepared query '(.*)' with no database connection\.$/, "Can.27t_get_the_prepared_query_.27Query.27_with_no_database_connection" ],
    [ /^Can't validate all ESTs\. There is\/are (.*) EST\(s\) that could not be validated\. See previous errors\.$/, "Can.27t_validate_all_ESTs" ],
    [ /^Can't validate all traces\. There is\/are (.*) trace(s) that could not be validated\. See previous errors\.$/, "Can.27t_validate_all_traces" ],
    [ /^Could not find a canonical URL for the controlled vocabulary (.*) when validating term (.*)\.$/, "Could_not_find_a_canonical_URL_for_the_controlled_vocabulary_CV_when_validating_term_Term" ],
    [ /^Could not find the protocol type (.*):(.*) defined in the wiki for '(.*)'\.$/, "Could_not_find_the_protocol_type_CV:Term_defined_in_the_wiki_for_.27Protocol.27" ],
    [ /^Could not parse '(.*)' as a date in format YYYY-MM-DD for the Date of Experiment. Please correct your IDF\.$/, "Could_not_parse_.27Date.27_as_a_date_in_format_YYYY-MM-DD_for_the_Date_of_Experiment._Please_correct_your_IDF" ],
    [ /^Could not parse '(.*)' as a date in format YYYY-MM-DD for the Public Release Date. Please correct your IDF\.$/, "Could_not_parse_.27Release_Date.27_as_a_date_in_format_YYYY-MM-DD_for_the_Public_Release_Date._Please_correct_your_IDF" ],
    [ /^Couldn't add the termsource specified by '(.*)' \((.*)\)\.$/, "Couldn.27t_add_the_termsource_specified_by_.27DB.27_(Name)" ],
    [ /^Couldn't connect to canonical URL source \((.*)\)(.*)$/, "Couldn.27t_connect_to_canonical_URL_source_(URL)" ],
    [ /^Couldn't connect to data source "(.*)", using username "(.*)" and password "(.*)"(.*)$/, "Couldn.27t_connect_to_data_source_\.22DSN\.22.2C_using_username_\.22Username\.22_and_password_\.22Password\.22" ],
    [ /^Couldn't expand (.*) in the (.*) \[(.*)\] field into a new set of attribute columns in the (.*) validator\.$/, "Couldn.27t_expand_Attribute_Value_in_the_Attribute_Heading_[Attribute_Name]_field_into_a_new_set_of_attribute_columns_in_the_Validator_validator" ],
    [ /^Couldn't expand (.*) in the (.*) \[(.*)\] field with any attribute columns in the (.*) validator\.$/, "Couldn.27t_expand_Value_in_the_Datum_[Name]_field_with_any_attribute_columns_in_the_Validator_validator" ],
    [ /^Couldn't expand the empty value in the (.*) \[(.*)\] field into a new set of attribute columns in the (.*) validator\.$/, "Couldn.27t_expand_the_empty_value_in_the_Value_[Attribute]_field_into_a_new_set_of_attribute_columns_in_the_Validator_validator" ],
    [ /^Couldn't expand the empty value in the (.*) \[(.*)\] field with any attribute columns in the (.*) validator\.$/, "Couldn.27t_expand_the_empty_value_in_the_Datum_[Name]_field_with_any_attribute_columns_in_the_Validator_validator" ],
    [ /^Couldn't fetch canonical source file '(.*)', and no cached copy found\.$/, "Couldn.27t_fetch_canonical_source_file_.27URL.27.2C_and_no_cached_copy_found" ],
    [ /^Couldn't fetch ESTs by primary ID; got response "(.*)" from NCBI\. Retrying\.$/, "Couldn.27t_fetch_ESTs_by_primary_ID;_got_response_\.22Response\.22_from_NCBI\._Retrying" ],
    [ /^Couldn't find any ESTs using when fetching for '(.*)' at NCBI\.$/, "Couldn.27t_find_any_ESTs_using_when_fetching_for_.27Term.27_at_NCBI" ],
    [ /^Couldn't find any ESTs using when searching for '(.*)' at NCBI\.$/, "Couldn.27t_find_any_ESTs_using_when_searching_for_.27Term.27_at_NCBI" ],
    [ /^Couldn't find cvterm '(.*)\.(.*)'\.$/, "Couldn.27t_find_cvterm_.27CV:Term.27" ],
    [ /^Couldn't find the accession (.*) in '(.*)' \((.*)\)\.$/, "Couldn.27t_find_the_accession_Accession_in_.27DB.27_(URL)" ],
    [ /^Couldn't find the EST identified by '(.*)' in search results from NCBI\.$/, "Couldn.27t_find_the_EST_identified_by_.27EST_Accession.27_in_search_results_from_NCBI" ],
    [ /^Couldn't find the term (.*) in '(.*)' \((.*)\)\.$/, "Couldn.27t_find_the_term_Term_in_.27DB.27_(URL)" ],
    [ /^Couldn't find the Trace identified by (.*) in search results from NCBI\.$/, "Couldn.27t_find_the_Trace_identified_by_Trace_ID_in_search_results_from_NCBI" ],
    [ /^Couldn't get a feature object for supposed transcript (.*)\.$/, "Couldn.27t_get_a_feature_object_for_supposed_transcript_Transcript_ID" ],
    [ /^Couldn't parse organism genus and species out of (.*) \[(.*)\]=(.*)\.$/, "Couldn.27t_parse_organism_genus_and_species_out_of_Attribute_[Name]=Value" ],
    [ /^Couldn't read file (.*)$/, "Couldn.27t_read_file_File" ],
    [ /^Couldn't read SDRF file (.*)\.$/, "Couldn.27t_read_SDRF_file_SDRF_File" ],
    [ /^Couldn't search for EST ID's; got response "(.*)" from NCBI\. Retrying\.$/, "Couldn.27t_search_for_EST_ID.27s;_got_response_\.22Error_Message\.22_from_NCBI" ],
    [ /^Couldn't tell if URL (.*) was valid\. Retrying\.$/, "Couldn.27t_tell_if_URL_URL_was_valid" ],
    [ /^Didn't process input line fully: (.*)$/, "Didn.27t_process_input_line_fully" ],
    [ /^Don't know how to parse the CV at URL: '(.*)' of type: '(.*)'\.$/, "Don.27t_know_how_to_parse_the_CV_at_URL:_.27URL.27_of_type:_.27URL_Type.27" ],
    [ /^Each term in Protocol Type REALLY SHOULD have a prefix if there is more than one type, even if there is only one term source ref \(e\.g\. (.*):(.*)\)\.$/, "Each_term_in_Protocol_Type_REALLY_SHOULD_have_a_prefix_if_there_is_more_than_one_type.2C_even_if_there_is_only_one_term_source_ref_(e.g._CV:Name)" ],
    [ /^Falling back to fetching remaining (.*) ESTs from FlyBase(\.\.\.)$/, "Falling_back_to_fetching_remaining_Number_Of_ESTs_ESTs_from_FlyBase" ],
    [ /^Fetching ESTs from (.*) to (.*)\.$/, "Fetching_ESTs_from_First_EST_to_Last_EST" ],
    [ /^Fetching feature (.*), (.*) of (.*)\.$/, "Fetching_feature_Feature_ID.2C_Feature_Number_of_Total_Features" ],
    [ /^Fetching (.*) ESTs from local modENCODE database(\.\.\.)$/, "Fetching_Number_Of_ESTs_ESTs_from_local_modENCODE_database" ],
    [ /^Fetching (.*) Traces from local modENCODE database(\.\.\.)$/, "Fetching_Number_Of_Traces_Traces_from_local_modENCODE_database" ],
    [ /^Fetching Traces from (.*) to (.*)(\.\.\.)$/, "Fetching_Traces_from_First_Trace_to_Last_Trace" ],
    [ /^Found a putative URL type \((.*)\) but not a URL \((.*)\) for controlled vocabulary (.*)\. Assuming this is a CV we're not meant to check\.$/, "Found_a_putative_URL_type_(URL_Type)_but_not_a_URL_(URL)_for_controlled_vocabulary_CV._Assuming_this_is_a_CV_we.27re_not_meant_to_check" ],
    [ /^Found a URL \((.*)\) but not a URL type \((.*)\), for controlled vocabulary (.*)\. Please check DBFieldsConf\.php$/, "Found_a_URL_(URL)_but_not_a_URL_type_(URL_Type).2C_for_controlled_vocabulary_CV._Please_check_DBFieldsConf.php" ],
    [ /^Found more than one feature '(.*)' with type (.*)\.$/, "Found_more_than_one_feature_.27Feature.27_with_type_Type" ],
    [ /^Given a termsource to validate with no term or accession; testing accession built into termsource: (.*)$/, "Given_a_termsource_to_validate_with_no_term_or_accession;_testing_accession_built_into_termsource:_Term_Source" ],
    [ /^Got back (.*) applied_protocols when (.*) applied_protocols were expected\.$/, "Got_back_Number_Of_Found_Protocols_applied_protocols_when_Number_Of_Expected_Protocols_applied_protocols_were_expected" ],
    [ /^input term '(.*)' is named in the IDF\/SDRF, but not in the wiki\.$/, "input_term_.27Input_Term.27_is_named_in_the_IDF\/SDRF.2C_but_not_in_the_wiki" ],
    [ /^Mismatch between feature locations in GFF files with the same IDs for ID=(.*)\.$/, "Mismatch_between_feature_locations_in_GFF_files_with_the_same_IDs_for_ID=GFF_ID" ],
    [ /^No BED file for (.*)$/, "No_BED_file_for_Data_Column" ],
    [ /^No Date of Experiment provided in the IDF, assuming current date(.*)\.$/, "No_Date_of_Experiment_provided_in_the_IDF.2C_assuming_current_date" ],
    [ /^No description for protocol (.*) found at (.*)\. Using URL as description\.$/, "No_description_for_protocol_Protocol_Name_found_at_Protocol_URL._Using_URL_as_description" ],
    [ /^No modENCODE project sub-group defined - defaulting to main group '(.*)'\.$/, "No_modENCODE_project_sub-group_defined_-_defaulting_to_main_group_.27Group_Name.27" ],
    [ /^No Public Release Date provided in the IDF, assuming current date(.*)\.$/, "No_Public_Release_Date_provided_in_the_IDF.2C_assuming_current_date" ],
    [ /^Nothing to validate; no term or accession given, and no accession built into termsource: (.*)$/, "Nothing_to_validate;_no_term_or_accession_given.2C_and_no_accession_built_into_termsource:_Term_Source" ],
    [ /^No validator for attribute (.*) \[(.*)\] with term source type (.*)\.$/, "No_validator_for_attribute_Attribute_[Name]_with_term_source_type_Term_Source_Type" ],
    [ /^No validator for attribute of type (.*)\.$/, "No_validator_for_attribute_of_type_Attribute_Type." ],
    [ /^No validator for data type (.*)\.$/, "No_validator_for_data_type_Data_Type." ],
    [ /^output term '(.*)' is named in the IDF\/SDRF, but not in the wiki\.$/, "output_term_.27Output_Term.27_is_named_in_the_IDF/SDRF.2C_but_not_in_the_wiki" ],
    [ /^Parsed line (.*)\.$/, "Parsed_line_Line_Number" ],
    [ /^Parsed (.*) trace records$/, "Parsed_Number_Of_Traces_trace_records" ],
    [ /^\(Parsing (.*)\.\.\./, "Parsing_CV" ],
    [ /^Parsing GFF file (.*)\.\.\.$/, "Parsing_GFF_file_GFF_File" ],
    [ /^Parsing list of ESTs from file (.*)\.$/, "Parsing_list_of_ESTs_from_file_EST_List_File" ],
    [ /^Parsing SDRF '(.*)'\.$/, "Parsing_SDRF_.27SDRF_File.27" ],
    [ /^Protocol '(.*)' has no protocol type definition in the IDF\.$/, "Protocol_.27Protocol.27_has_no_protocol_type_definition_in_the_IDF" ],
    [ /^Relationship between '(.*) and (.*)' doesn't have a valid CVTerm type '(.*)'$/, "Relationship_between_.27FeatureA_and_FeatureB.27_doesn.27t_have_a_valid_CVTerm_type_.27Type.27" ],
    [ /^Removing datum '(.*)' as input from '(.*)'; not found in IDF's Protocol Parameters\.$/, "Removing_datum_.27Datum_Name.27_as_input_from_.27Protocol.27;_not_found_in_IDF.27s_Protocol_Parameters" ],
    [ /^ Retrieved (.*) traces\. Validating\.\.\.$/, "Retrieved_Number_Of_Traces_traces" ],
    [ /^Searching ESTs from (.*) to (.*)\.$/, "Searching_ESTs_from_First_EST_to_Last_EST" ],
    [ /^Term source '(.*)' \((.*)\) does not contain a definition for attribute '(.*)\[(.*)\]=(.*)' of datum '(.*) \[(.*)\]=(.*)' of protocol '(.*)'\.$/, "Term_source_.27DB.27_(URL)_does_not_contain_a_definition_for_attribute_.27Attribute[Name]=Value.27_of_datum_.27Datum_[Name]=Value.27_of_protocol_.27Protocol.27" ],
    [ /^Term source '(.*)' \((.*)\) does not contain a definition for attribute '(.*)\[(.*)\]=(.*)' of protocol '(.*)'\.$/, "Term_source_.27DB.27_(URL)_does_not_contain_a_definition_for_attribute_.27Attribute[Name]=Value.27_of_protocol_.27Protocol.27" ],
    [ /^Termsource '(.*)' \((.*)\) is not a valid DBXref for attribute '(.*)\[(.*)\]=(.*)'$/, "Termsource_.27DB.27_(URL)_is_not_a_valid_DBXref_for_attribute_.27Attribute[Name]=Value.27" ],
    [ /^Term source '(.*)' \((.*)\) does not contain a definition for datum '(.*) \[(.*)\]=(.*)' of protocol '(.*)'\.$/, "Term_source_.27DB.27_(URL)_does_not_contain_a_definition_for_datum_.27Datum_[Name]=Value.27_of_protocol_.27Protocol.27" ],
    [ /^Termsource '(.*)' \((.*)\) is not a valid DBXref for datum '(.*)\[(.*)\]=(.*)'$/, "Termsource_.27DB.27_(URL)_is_not_a_valid_DBXref_for_datum_.27Datum[Name]=Value.27" ],
    [ /^Termsource '(.*)' \((.*)\) is not a valid DBXref\.$/, "Termsource_.27DB.27_(URL)_is_not_a_valid_DBXref" ],
    [ /^Termsource '(.*)' \((.*)\) is not a valid term source\/DBXref for experiment_prop '(.*)=(.*)'\.$/, "Termsource_.27DB.27_(URL)_is_not_a_valid_term_source/DBXref_for_experiment_prop_.27Experiment_Property=Value.27" ],
    [ /^Term source '(.*)' \((.*)\) does not contain a definition for protocol '(.*)'\.$/, "Term_source_.27DB.27_(URL)_does_not_contain_a_definition_for_protocol_.27Protocol.27" ],
    [ /^Termsource '(.*)' \((.*)\) is not a valid DBXref for protocol '(.*)'\.$/, "Termsource_.27DB.27_(URL)_is_not_a_valid_DBXref_for_protocol_.27Protocol.27" ],
    [ /^The CV name (.*) is already used for (.*), but at attempt has been made to redefine it for (.*)\. Please check your IDF\.$/, "The_CV_name_CV_is_already_used_for_URL.2C_but_at_attempt_has_been_made_to_redefine_it_for_New_URL._Please_check_your_IDF" ],
    [ /^The Date of Experiment '(.*)' was not in the format YYYY-MM-DD. It has been parsed as (.*), i.e. (.*)\.$/, "The_Date_of_Experiment_.27Input_Date.27_was_not_in_the_format_YYYY-MM-DD._It_has_been_parsed_as_Parsed_Date" ],
    [ /^The protocol '(.*)' has (.*) Protocol Types in the wiki, and (.*) in the IDF\.$/, "The_protocol_.27Protocol.27_has_Number_Of_Wiki_Protocol_Types_Protocol_Types_in_the_wiki.2C_and_Number_Of_IDF_Protocol_Types_in_the_IDF" ],
    [ /^The Protocol Type field for (.*) is missing from the IDF\.$/, "The_Protocol_Type_field_for_Protocol_is_missing_from_the_IDF" ],
    [ /^The Protocol \(Type\) Term Source REF field for (.*) is missing from the IDF\.$/, "The_Protocol_Term_Source_REF_field_for_Protocol_is_missing_from_the_IDF" ],
    [ /^The Public Release Date '(.*)' was not in the format YYYY-MM-DD. It has been parsed as (.*), i.e. (.*)\.$/, "The_Public_Release_Date_.27Input_Date.27_was_not_in_the_format_YYYY-MM-DD._It_has_been_parsed_as_Parsed_Date" ],
    [ /^There are (.*) input parameters according to the wiki/, "There_are_Number_Of_Input_Parameters_input_parameters_according_to_the_wiki" ],
    [ /^There are (.*) output parameters according to the wiki/, "There_are_Number_Of_Output_Parameters_input_parameters_according_to_the_wiki" ],
    [ /^The sequence region feature (.*) does not have an associated organism. This may be okay, as long as the feature already exists in the database\.$/, "The_sequence_region_feature_Sequence_Region_Feature_does_not_have_an_associated_organism" ],
    [ /^The term source (.*) for Protocol Type '(.*)' is not mentioned in the Protocol Term Source REF field\.$/, "The_term_source_CV_for_Protocol_Type_.27Protocol_Type.27_is_not_mentioned_in_the_Protocol_Term_Source_REF_field" ],
    [ /^Type '(.*):(.*)' is not a valid CVTerm for attribute '(.*)\[(.*)\]=(.*)'$/, "Type_.27CV:Term.27_is_not_a_valid_CVTerm_for_attribute_.27Attribute[Name]=Value.27" ],
    [ /^Type '(.*):(.*)' is not a valid CVTerm\.$/, "Type_.27CV:Term.27_is_not_a_valid_CVTerm" ],
    [ /^Type '(.*):(.*)' is not a valid CVTerm for datum '(.*)\[(.*)\]=(.*)'\.$/, "Type_.27CV:Term.27_is_not_a_valid_CVTerm_for_datum_.27Datum[Name]=Value.27" ],
    [ /^Type '(.*):(.*)' is not a valid CVTerm for experiment_prop '(.*)=(.*)'\.$/, "Type_.27CV:Term.27_is_not_a_valid_CVTerm_for_experiment_prop_.27Experiment_Property=Value.27" ],
    [ /^Type '(.*):(.*)' is not a valid CVTerm for feature '(.*)'$/, "Type_.27CV:Term.27_is_not_a_valid_CVTerm_for_feature_.27Feature.27" ],
    [ /^Unable to find accession for (.*) in (.*)$/, "Unable_to_find_accession_for_Term_in_CV" ],
    [ /^Unable to find the '(.*)' field in the SDRF even though it is defined in the IDF\.$/, "Unable_to_find_the_.27IDF_Input_Param.27_field_in_the_SDRF_even_though_it_is_defined_in_the_IDF" ],
    [ /^Unable to use a '(.*)' as a ModENCODE::ErrorHandler logger as it does not subclass ModENCODE::ErrorHandler\. Reverting to default\.$/, "Unable_to_use_a_.27Logger.27_as_a_ModENCODE::ErrorHandler_logger_as_it_does_not_subclass_ModENCODE::ErrorHandler\._Reverting_to_default" ],
    [ /^Using cached copy of CV for (.*); no change on server\.$/, "Using_cached_copy_of_CV_for_CV;_no_change_on_server" ],
    [ /^Validating (.*) ESTs\.\.\.$/, "Validating_Number_Of_ESTs_ESTs" ],
    [ /^Validating (.*) Traces\.\.\.$/, "Validating_Number_Of_Traces_Traces" ],
    [ /^Cannot write experiment to file (.*), defaulting to STDOUT\./, "Cannot_write_experiment_to_file_Output_File.2C_defaulting_to_STDOUT" ]
  ]
end
