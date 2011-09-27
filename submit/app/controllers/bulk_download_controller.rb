require 'rubygems'
require 'tree'
module ActionView
  module Helpers
    module FormOptionsHelper
      # Patch in new version of options_for_select that supports disabling options
      def extract_selected_and_disabled(selected)
        if selected.is_a?(Hash)
          [selected[:selected], selected[:disabled]]
        else
          [selected, nil]
        end
      end
      def options_for_select(container, selected = nil)
        return container if String === container

        container = container.to_a if Hash === container
        selected, disabled = extract_selected_and_disabled(selected)

        options_for_select = container.inject([]) do |options, element|
          text, value = option_text_and_value(element)
          selected_attribute = ' selected="selected"' if option_value_selected?(value, selected)
          disabled_attribute = ' disabled="disabled"' if disabled && option_value_selected?(value, disabled)
          options << %(<option value="#{html_escape(value.to_s)}"#{selected_attribute}#{disabled_attribute}>#{html_escape(text.to_s)}</option>)
        end

        options_for_select.join("\n")
      end
    end
  end
end
module FancyGroupedOptions
  def to_options
    self.map { |group| group_name = group[0]; group_opts = group[1..-1].map { |k, v| [ v[:description], k.to_s ] }; [ group_name, group_opts ] }
  end
  def get(key)
    return if key.nil?; val = self.inject(Array.new) { |accum, arr| accum+arr[1..-1] }.find_all { |val| val.is_a?(Array) }.find { |val| val[0] == key.to_sym }; return val.nil? ? nil : val[1]
  end
end
class BulkDownloadController < ApplicationController
  def index
    init_options_from_params
    @selected_data = get_selected_freeze_data(@freeze_data, @filter_options[:experiment_types], @filter_options[:data_types], @filter_options[:tissues], @filter_options[:strains], @filter_options[:cell_lines], @filter_options[:stages], @filter_options[:antibodies], @filter_options[:array_platforms], @filter_options[:projects], @filter_options[:labs], @filter_options[:compounds], @filter_options[:rnai_targets])
  end
  def matrix_refresh
    init_options_from_params
    build_matrix
    render :partial => "matrix_display"
  end
    
  def define_matrix
    @freeze_files = get_freeze_files
    just_filenames = @freeze_files.map { |k, v| v.nil? ? [] : v.map { |v2| v2[1] unless v2.nil? } }.flatten.compact
    @selected_freeze_id = params[:selected_freeze]
    @selected_freeze_files = just_filenames.find_all { |fname| fname == params[:selected_freeze] }.map { |fname| 
      if fname =~ /^combined_/ then
        date = fname.match(/^combined_(.*)/)[1]
        [ "dmelanogaster_#{date}", "celegans_#{date}" ]
      else
        fname
      end
    }.flatten
    @freeze_data = get_freeze_data(@selected_freeze_files)

    @col_types = [ "Compound", "Cell Line", "Strain", ["Stage", "Stage/Treatment"], "Tissue", "Antibody", "Organism", "Assay" ]
    @row_types = @col_types
    @group_by_types = [ ["None", ""], "Cell Line", "Strain", ["Stage", "Stage/Treatment"], "Tissue", "Antibody", "Organism", "Assay" ]
    @split_by_types = [ ["None", ""], "Organism", "Assay" ]
    @show_attrs_types = [ ["None", ""] ] + @col_types

    @selected_row_types = params[:rows] || []
    @selected_col_types = params[:cols] || []
    @selected_show_attrs_types = params[:cols] || []

    @stage_onto = get_stage_ontologies

    render :partial => "define_matrix"
  end
  def matrix
    @freeze_files = get_freeze_files
    just_filenames = @freeze_files.map { |k, v| v.nil? ? [] : v.map { |v2| v2[1] unless v2.nil? } }.flatten.compact
    @selected_freeze_id = params[:selected_freeze]
    @selected_freeze_files = just_filenames.find_all { |fname| fname == params[:selected_freeze] }.map { |fname| 
      if fname =~ /^combined_/ then
        date = fname.match(/^combined_(.*)/)[1]
        [ "dmelanogaster_#{date}", "celegans_#{date}" ]
      else
        fname
      end
    }.flatten
    @freeze_data = get_freeze_data(@selected_freeze_files)
    header_translation = {
        "Antibody" => :antibodies,
        "Platform" => :array_platforms,
        "Compound" => :compounds,
        "RNAi Target" => :rnai_targets,
        "Stage/Treatment" => :stages
    }

    @experiment_type = params[:selected_experiment_type]
    @data_type = params[:selected_data_type]
    @tissue = params[:selected_tissue]
    @strain = params[:selected_strain]
    @cell_line = params[:selected_cell_line]
    @stage = params[:selected_stage]
    @antibody = params[:selected_antibody]
    @array_platform = params[:selected_array_platform]
    @project = params[:selected_project]
    @lab = params[:selected_lab]
    @compound = params[:selected_compound]
    @rnai_target = params[:selected_rnai_target]

    @freeze_data = get_selected_freeze_data(@freeze_data, @experiment_type, @data_type, @tissue, @strain, @cell_line, @stage, @antibody, @array_platform, @project, @lab, @compound, @rnai_target)

    @groups = params[:group_by].empty? ? [ nil ] : @freeze_data.map { |e| e[params[:group_by]].split(/, /) }.flatten.uniq
    @splits = params[:split_by].empty? ? [ nil ] : @freeze_data.map { |e| e[params[:split_by]].split(/, /) }.flatten.uniq


    if (@splits.size > 0) then
      @data_by_split = Hash.new
      @splits.each { |split|
        @data_by_split[split] = split.nil? ? @freeze_data : @freeze_data.find_all { |e| e[params[:split_by]].split(/, /).include?(split) }
      }
    else
      @data_by_split = @freeze_data
    end

    @cols_product = Hash.new
    @rows_product = Hash.new
    @show_attrs = params[:show_attrs].nil? ? [] : params[:show_attrs].reject { |a| a.empty? }

    @data_by_split.each { |splitkey, splitdata|


      data_by_group = Hash.new
      if (@groups.size > 0) then
        @groups.each { |group|
          data_by_group[group] = group.nil? ? splitdata : splitdata.find_all { |e| e[params[:group_by]].split(/, /).include?(group) }
        }
      else
        data_by_group = splitdata
      end

      mapped_params = params
      if @freeze_data.find { |project_info| project_info["Experimental Factor"] } then
        mapped_params[:cols] = mapped_params[:cols].map { |col| header_translation[col] ? header_translation[col] : col }
        mapped_params[:rows] = mapped_params[:rows].map { |row| header_translation[row] ? header_translation[row] : row  }
      end

      @cols = Array.new
      uniq_by_col = Hash.new { |h, k| h[k] = Array.new }
      mapped_params[:cols].each { |col|
        splitdata.each { |e|
          uniq_by_col[col].push e[col].split(/, /) if e[col]
        }
      }
      uniq_by_col.values.each { |v| v.flatten!.uniq! }

      @cols = uniq_by_col
      @numcols = @cols.values.map { |v| v.size }.inject { |numcols, s| numcols * s }

      @rows = Array.new
      uniq_by_row = Hash.new { |h, k| h[k] = Array.new }
      mapped_params[:rows].each { |row|
        splitdata.each { |e|
          uniq_by_row[row].push e[row].split(/, /) if e[row]
        }
      }
      uniq_by_row.values.each { |v| v.flatten!.uniq! }
      @rows = uniq_by_row
      @numrows = @rows.values.map { |v| v.size }.inject { |numrows, s| numrows * s }
    
      splitkey = header_translation[splitkey] ? header_translation[splitkey] : splitkey
      @cols_product[splitkey] = uniq_by_col.map { |col, vals| vals.map { |val| { col => val } } }.inject { |prod, cols| prod.product(cols) }.map { |prod| prod.is_a?(Array) ? prod : [ prod ] }.each { |prod| prod.flatten! }.uniq.map { |prod| prod.inject { |h, i| h.merge(i) } }
      @rows_product[splitkey] = uniq_by_row.map { |row, vals| vals.map { |val| { row => val } } }.inject { |prod, rows| prod.product(rows) }.map { |prod| prod.is_a?(Array) ? prod : [ prod ] }.each { |prod| prod.flatten! }.uniq.map { |prod| prod.inject { |h, i| h.merge(i) } }
      data_by_group.each { |group, data|
        data_by_col_combos = Hash.new
        @cols_product[splitkey].each { |restriction|
          matching = data.find_all { |e|
            restriction.find { |k, v| 
              #render :text => v.pretty_inspect; return
              if e[k].nil? then
                true
              elsif e[k].is_a?(Array) then
                !e[k].include?(v)
              elsif !e[k].split(/, /).include?(v) then
                true
              else
                false
              end
#              e[k].nil? || (e[k].is_a?(Array) && !e[k].include?(v)) || !e[k].split(/, /).include?(v) 
            }.nil?
          }
          data_by_col_combos[restriction] = matching if matching.size > 0
        }
        data_by_col_combos.each { |colrestr, data|
          data_by_row_combos = Hash.new
          @rows_product[splitkey].each { |restriction|
            matching = data.find_all { |e|
              restriction.find { |k, v| 
                e[k].nil? || !e[k].split(/, /).include?(v) 
              }.nil?
            }
            data_by_row_combos[restriction] = matching if matching.size > 0
          }
          data_by_col_combos[colrestr] = data_by_row_combos
        }
        data_by_group[group] = data_by_col_combos
      }

      @data_by_split[splitkey] = data_by_group
    }

    @show_checkboxes = params[:show_checkboxes] == "Generate HTML Checkboxes" ? true : false

    respond_to do |format|
      format.html {
      }
      format.text {
        render :partial => "matrix_csv"
      }
      format.xls {
        render :text => proc { |response, output|
          make_excel(output)
          output.flush
        }
      }
    end

  end

#private
  def make_excel(output_obj)
    require 'spreadsheet'
    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new
    @data_by_split.each do |splitkey, data_by_group|
      sheet = book.create_worksheet
      sheet.name = splitkey.nil? ? "Project Matrix" : splitkey
      if @groups.size > 1 then
        # Header row
        col = 0
#        mrg = Spreadsheet::Format.new :hoizontal_align => :merge
#        bold = Spreadsheet::Format.new :weight => :bold
        @groups.each do |group|
          sheet.row(0).push group
          groupwidth = data_by_group[group].size
          groupwidth.times { |g|
#            sheet.row(col).set_format(mrg) if g < (groupwidth-1)
#            sheet.row(col).add_format(bold)
          }
        end
      end
      out = StringIO.new ''
      book.write(out)
      output_obj.write(out.read)
    end
  end
  def get_stage_ontologies
    freeze_dir = "#{RAILS_ROOT}/config/freeze_data/"
    worm_obo = File.read(File.join(freeze_dir, "worm_development.obo"))
    fly_obo = File.read(File.join(freeze_dir, "fly_development.obo"))
    worm_tree = parse_obo(worm_obo)
    fly_tree = parse_obo(fly_obo)
    return { "Caenorhabditis elegans" => worm_tree, "Drosophila melanogaster" => fly_tree }
  end
  def parse_obo(obo_data)
    stanzas = obo_data.split(/^(\[\w*\])/)
    stanzas.shift
    tree_lookup = Hash.new { |h, k| h[k] = Tree::TreeNode.new(k) }
    while (stanza = stanzas.shift) do
      stanza += stanzas.shift
      stanza = stanza.split(/[\r\n]+/)
      if stanza[0] == "[Term]" then
        stanza = stanza.map { |row| row.split(/: /, 2) }
        name = stanza.find { |term| term[0] == "name" }[1]
        relationships = stanza.find_all { |term| term[0] == "relationship" && term[1] =~ /^part_of/ }
        relationships = stanza.find_all { |term| term[0] == "is_a" } unless relationships.size > 0
        relationships = relationships.map { |term| term[1].split(/ ! /).last }
        relationships.each { |other_term|
          tree_lookup[other_term].add(tree_lookup[name])
        }
      end
    end
    return tree_lookup.values.first.root
  end
  def get_freeze_files()
    freeze_files = Hash.new { |h, k| h[k] = Array.new }
    freeze_files[""] = [ nil ]
    freeze_dir = "#{RAILS_ROOT}/config/freeze_data/"
    if File.directory? freeze_dir then
      Dir.glob(File.join(freeze_dir, "*.txt")).each { |f| 
        fname = File.basename(f)[0..-5]
        (organism, date) = fname.split(/_/)
        organism = organism[0..0].upcase + ". " + organism[1..-1]
        freeze_files[organism].push [ date, fname ]
      }
    end

    # Nightlies
    freeze_dir = "#{RAILS_ROOT}/config/freeze_data/nightly/"
    if File.directory? freeze_dir then
      Dir.glob(File.join(freeze_dir, "celegans_*.txt")).each { |f| 
        fname = File.basename(f)[0..-5]
        (organism, date) = fname.split(/_/)
        organism = organism[0..0].upcase + ". " + organism[1..-1]
        freeze_files[organism + " nightlies"].push [ date, fname ]
      }
      Dir.glob(File.join(freeze_dir, "dmelanogaster_*.txt")).each { |f| 
        fname = File.basename(f)[0..-5]
        (organism, date) = fname.split(/_/)
        organism = organism[0..0].upcase + ". " + organism[1..-1]
        freeze_files[organism + " nightlies"].push [ date, fname ]
      }
    end

    freeze_files = freeze_files.to_a
    freeze_files = freeze_files + { "Combined" => freeze_files.map { |k, v| v }.flatten(1).reject { |f| f.nil? }.map { |f| [ f[0], "combined_#{f[0]}" ] }.uniq }.to_a
    freeze_files.each { |file, dates| dates.sort! { |d1, d2| Date.parse(d2[0]) <=> Date.parse(d1[0]) } }
    freeze_files.each { |file, dates| dates.each { |date| date[0] += " #{date[1][0..3]}" unless date.nil?; }; dates.first[0] += " (newest)" if dates.first }
    @sort_order = {
      "" => 0,
      "C. elegans nightlies" => 1,
      "D. melanogaster nightlies" => 2,
      "C. elegans" => 3,
      "D. melanogaster" => 4,
      "Combined" => 5
    }
    freeze_files = freeze_files.to_a.sort { |group1, group2| @sort_order[group1[0]] <=> @sort_order[group2[0]] }
    return freeze_files
  end
  def get_freeze_data(freeze_files)
    data = Array.new
    freeze_files.each { |freeze_file|
      filename = nil
      if File.exists?("#{RAILS_ROOT}/config/freeze_data/#{freeze_file}.txt") then
        filename = "#{RAILS_ROOT}/config/freeze_data/#{freeze_file}.txt"
      elsif File.exists?("#{RAILS_ROOT}/config/freeze_data/nightly/#{freeze_file}.txt") then
        filename = "#{RAILS_ROOT}/config/freeze_data/nightly/#{freeze_file}.txt"
      end

      if filename then
        File.open(filename) { |f|
          headers = f.gets.chomp.split(/\t/)
          while ((line = f.gets) != nil) do
            fields = line.chomp.split(/\t/).map { |field| (field == "" ? "N/A" : field) }
            d = Hash.new; headers.each_index { |n| d[headers[n]] = (fields[n].nil? ? nil : fields[n].gsub(/^"|"$/, '')) }
            data.push d
          end
        }
      end
    }
    extract_and_attach_factor_info(data)
    return data
  end

  def extract_and_attach_factor_info(freeze_data)
    # We group some fields together and put them into symbol-keyed entries in the @freeze_data hash
    # because older generated spreadsheets had these fields separate
    # This is the mapping of human-readable column name to grouped field, which gets used when
    # defining a matrix view
    @freeze_header_translation = {
      "Antibody" => :antibodies,
      "Platform" => :array_platforms,
      "Compound" => :compounds,
      "RNAi Target" => :rnai_targets,
      "Stage/Treatment" => :stages,
    }

    if freeze_data.find { |project_info| project_info["Experimental Factor"] } then
      freeze_data.each { |project_info| 
        factors = project_info["Experimental Factor"].split(/[;,]\s*/).flatten.uniq.inject(Hash.new { |h, k| h[k] = Array.new }) { |h, factor| 
          (k,v) = factor.split(/=/)
          h[k].push v
          h
        }
        treatments = project_info["Treatment"].split(/[;,]\s*/).flatten.uniq.inject(Hash.new { |h, k| h[k] = Array.new }) { |h, treatment| 
          (k,v) = treatment.split(/=/)
          h[k].push v
          h
        }

        project_info[:antibodies]      = factors["AbName"].zip(factors["Target"]).map { |pair| pair.join("=>") }
        project_info[:array_platforms] = (factors["Platform"].blank? ? factors["ArrayPlatform"] : factors["Platform"])
        project_info[:compounds]       = factors["SaltConcentration"].map  { |compound| "SaltConcentration=#{compound}" }
        project_info[:rnai_targets]    = treatments["RNAiTarget"]
        stage_info = (project_info["Stage"] || project_info["Stage/Treatment"] || "")
        stage_info_m = stage_info.match(/^(.*):/)
        project_info[:stages]          = stage_info_m.nil? ? stage_info.split(/,\s*/) : [ stage_info_m[1] ]
        project_info["Stage"]          = stage_info_m.nil? ? stage_info.split(/,\s*/) : [ stage_info_m[1] ]
        project_info[:submission_id]   = project_info["Submission ID"].sub(/ .*/, '')

        project_info[:antibodies] = ["N/A"] if project_info[:antibodies].size == 0
        project_info[:array_platforms] = ["N/A"] if project_info[:array_platforms].size == 0
        project_info[:compounds] = ["N/A"] if project_info[:compounds].size == 0
        project_info[:rnai_targets] = ["N/A"] if project_info[:rnai_targets].size == 0
        project_info[:stages] = ["N/A"] if project_info[:stages].size == 0
      }
    else
      freeze_data.each { |project_info|
        project_info[:antibodies] = project_info["Antibody"].split(/, /)
        project_info[:array_platforms] = project_info["Platform"].split(/, /)
        project_info[:compounds] = project_info["Compound"].split(/, /)
        project_info[:rnai_targets] = project_info["RNAi Target"].split(/, /)
        project_info[:stages] = project_info["Stage/Treatment"].split(/, /)
        project_info[:submission_id]   = project_info["Submission ID"].sub(/ .*/, '')

        project_info[:antibodies] = ["N/A"] if project_info[:antibodies].size == 0
        project_info[:array_platforms] = ["N/A"] if project_info[:array_platforms].size == 0
        project_info[:compounds] = ["N/A"] if project_info[:compounds].size == 0
        project_info[:rnai_targets] = ["N/A"] if project_info[:rnai_targets].size == 0
        project_info[:stages] = ["N/A"] if project_info[:stages].size == 0
      }
    end
  end

  def get_selected_freeze_data(freeze_data, experiment_type, data_type, tissue, strain, cell_line, stage, antibody, array_platform, project, lab, compound, rnai_target)
    freeze_data = freeze_data.reject { |project_info| (experiment_type & project_info["Assay"].split(/, /)).size == 0 } unless (experiment_type.nil? || experiment_type.size == 0)
    freeze_data = freeze_data.reject { |project_info| (data_type & project_info["Data Type"].split(/, /)).size == 0 } unless (data_type.nil? || data_type.size == 0)
    freeze_data = freeze_data.reject { |project_info| (tissue & project_info["Tissue"].split(/, /)).size == 0 } unless (tissue.nil? || tissue.size == 0)
    freeze_data = freeze_data.reject { |project_info| (strain & project_info["Strain"].split(/, /)).size == 0 } unless (strain.nil? || strain.size == 0)
    freeze_data = freeze_data.reject { |project_info| (cell_line & project_info["Cell Line"].split(/, /)).size == 0 } unless (cell_line.nil? || cell_line.size == 0)
    freeze_data = freeze_data.reject { |project_info| (project & project_info["Project"].split(/, /)).size == 0 } unless (project.nil? || project.size == 0)
    freeze_data = freeze_data.reject { |project_info| (lab & project_info["Lab"].split(/, /)).size == 0 } unless (lab.nil? || lab.size == 0)


    freeze_data = freeze_data.reject { |project_info| (stage & project_info[:stages]).size == 0 } unless (stage.nil? || stage.size == 0)
    freeze_data = freeze_data.reject { |project_info| (antibody & project_info[:antibodies]).size == 0 } unless (antibody.nil? || antibody.size == 0)
    freeze_data = freeze_data.reject { |project_info| (array_platform & project_info[:array_platforms]).size == 0 } unless (array_platform.nil? || array_platform.size == 0)
    freeze_data = freeze_data.reject { |project_info| (compound & project_info[:compounds]).size == 0 } unless (compound.nil? || compound.size == 0)
    freeze_data = freeze_data.reject { |project_info| (rnai_target & project_info[:rnai_targets]).size == 0 } unless (rnai_target.nil? || rnai_target.size == 0)

    # Only released data?
    freeze_data = freeze_data.reject { |project_info| project_info["Status"] != "released" }


    return freeze_data
  end
  def build_matrix
    init_options_from_params
    @no_content = false
    @selected_freeze_data = get_selected_freeze_data(@freeze_data, @filter_options[:experiment_types], @filter_options[:data_types], @filter_options[:tissues], @filter_options[:strains], @filter_options[:cell_lines], @filter_options[:stages], @filter_options[:antibodies], @filter_options[:array_platforms], @filter_options[:projects], @filter_options[:labs], @filter_options[:compounds], @filter_options[:rnai_targets]) if @selected_freeze_data.nil?
    @data_by_split_and_group_and_columns_and_rows = {}

    # Get matrix_opts from template
    if (@matrix_opts = @matrix_styles.get(@selected_matrix_style)).nil? then
      # Failing that, get user-defined params
      if (@matrix_opts = params[:matrix]).nil? then
        # Failing that, don't bother building the matrix
        return
      end
    end
    @matrix_opts[:cols] ||= []
    @matrix_opts[:rows] ||= []
    is_old_experiment = @freeze_data.find { |e| e["Experimental Factor"] }.nil? ? false : true
    # Remap column/row headings for older experiments
    if is_old_experiment then
      @matrix_opts[:cols] = @matrix_opts[:cols].map { |col| @freeze_header_translation[col] || col }
      @matrix_opts[:rows] = @matrix_opts[:rows].map { |row| @freeze_header_translation[row] || row }
    end

    # If group or split is set, then find all the distinct values in the column that we're grouping/splitting on
    @splits = (@matrix_opts[:split_by].nil? || @matrix_opts[:split_by].empty?) ? [ nil ] : @selected_freeze_data.map { |e| e[@matrix_opts[:split_by]].split(/,\s*/) }.flatten.uniq
    @groups = (@matrix_opts[:group_by].nil? || @matrix_opts[:group_by].empty?) ? [ nil ] : @selected_freeze_data.map { |e| e[@matrix_opts[:group_by]].split(/,\s*/) }.flatten.uniq

    # Collect all the data into each split section
    @splits.each { |split|
      @data_by_split_and_group_and_columns_and_rows[split] = split.nil? ? @selected_freeze_data : 
        @selected_freeze_data.find_all { |e| e[@matrix_opts[:split_by]].split(/,\s*/).include?(split) }
    }

    # Hashes to hold list of column and row headings
    @cols_product = Hash.new
    @rows_product = Hash.new

    # Within each chunk of (split) data, divide into chunks of data by group
    @data_by_split_and_group_and_columns_and_rows.each { |splitkey, splitdata|
      (splitkey = @freeze_header_translation[splitkey] || splitkey) if is_old_experiment

      data_by_group_and_columns_and_rows = {}
      @groups.each { |group|
        data_by_group_and_columns_and_rows[group] = group.nil? ? splitdata :
          splitdata.find_all { |e| e[@matrix_opts[:group_by]].split(/,\s*/).include?(group) }
      }

      # Get unique values in each field that's going to be (part of) a column header
      uniq_by_col = Hash.new { |h, k| h[k] = Array.new }
      @matrix_opts[:cols].each { |col|
        splitdata.each { |e| uniq_by_col[col].push e[col].split(/,\s*/) if e[col] }
      }
      uniq_by_col.values.each { |v| v.flatten!.uniq! }

      # Get unique values in each field that's going to be (part of) a row header
      uniq_by_row = Hash.new { |h, k| h[k] = Array.new }
      @matrix_opts[:rows].each { |row|
        splitdata.each { |e| uniq_by_row[row].push e[row].split(/,\s*/) if e[row] }
      }
      uniq_by_row.values.each { |v| v.flatten!.uniq! }

      # Generate cross product column/row headings (if two+ fields are being used to make column/row headings)
      if uniq_by_col.size > 0 && uniq_by_col.size > 0 then
        na_col = {}; uniq_by_col.each { |k, v| na_col[k] = v.delete("N/A") }
        na_row = {}; uniq_by_row.each { |k, v| na_row[k] = v.delete("N/A") }
        @cols_product[splitkey] = uniq_by_col.map { |col, vals| vals.map { |val| { col => val } } }.inject { |prod, cols| prod.product(cols) }.map { |prod| prod.is_a?(Array) ? prod : [ prod ] }.each { |prod| prod.flatten! }.uniq.map { |prod| prod.inject { |h, i| h.merge(i) } }
        @rows_product[splitkey] = uniq_by_row.map { |row, vals| vals.map { |val| { row => val } } }.inject { |prod, rows| prod.product(rows) }.map { |prod| prod.is_a?(Array) ? prod : [ prod ] }.each { |prod| prod.flatten! }.uniq.map { |prod| prod.inject { |h, i| h.merge(i) } }
        na_col.each { |k, v| @cols_product[splitkey].push na_col unless na_col.nil? }
        na_row.each { |k, v| @rows_product[splitkey].push na_row unless na_row.nil? }
      else
        @no_content = true
        @cols_product[splitkey] = []
        @rows_product[splitkey] = []
      end

      # Within each chunk of (grouped) data, divide into chunks by column heading
      data_by_group_and_columns_and_rows.each { |groupkey, groupdata|
        data_by_columns_and_rows = {}
        group_index = index_freeze_data(groupdata)
        @cols_product[splitkey].each { |col_selector|
          indices = []
          col_selector.each { |k, v|
            indices += group_index[k][v]
          }
          data_by_columns_and_rows[col_selector] = groupdata.values_at(*indices)
        }

        # Within each chunk of (column) data, divide into chunks by row heading
        data_by_columns_and_rows.each { |columnkey, coldata|
          data_by_rows = {}
          col_indices = {}; coldata.each { |e| col_indices[e[:idx]] = true }
          # Using col_indices above, use group_index below and only keep indices that land in col_indices

          @rows_product[splitkey].each { |row_selector|
            indices = []
            row_selector.each { |k, v|
              indices += group_index[k][v].find_all { |e| col_indices[e] }
            }
            data_by_rows[row_selector] = groupdata.values_at(*indices)
          }
          
          # Store the row-chunked data by column
          data_by_columns_and_rows[columnkey] = data_by_rows
        }

        # Store the column-chunked data by group
        data_by_group_and_columns_and_rows[groupkey] = data_by_columns_and_rows
      }

      # Store the group-chunked data by split
      @data_by_split_and_group_and_columns_and_rows[splitkey] = data_by_group_and_columns_and_rows
    }

    # Done; the nested hash (plus @groups, @splits, @cols_product, and @rows_product) can be used to generate a table
  end

  def init_options_from_params
    return if @options_initted
    @options_initted = true
    @freeze_files = get_freeze_files
    just_filenames = @freeze_files.map { |k, v| v.nil? ? [] : v.map { |v2| v2[1] unless v2.nil? } }.flatten.compact
    @selected_freeze_id = params[:selected_freeze]
    @prev_selected_freeze_id = params[:prev_selected_freeze]
    @selected_freeze_files = just_filenames.find_all { |fname| fname == @selected_freeze_id }.map { |fname| 
      if fname =~ /^combined_/ then
        date = fname.match(/^combined_(.*)/)[1]
        [ "dmelanogaster_#{date}", "celegans_#{date}" ]
      else
        fname
      end
    }.flatten
    @freeze_data = get_freeze_data(@selected_freeze_files)

    # Matrix layout
    @selected_matrix_style = (params[:matrix_style].nil? || params[:matrix_style].empty?) ? nil : params[:matrix_style]
    @matrix_styles = [
      [ "Cell Line",
        [ :cell_line_vs_antibodies,     { :rows => [ "Cell Line" ],       :cols => [ "Antibody" ],     :description => "Cell Line / Antibody" } ],
        [ :cell_line_vs_stage,          { :rows => [ "Cell Line" ],       :cols => [ "Stage" ],        :description => "Cell Line / Stage" } ]
      ],
      [ "Strain",
        [ :strain_vs_antibodies,        { :rows => [ "Strain" ],          :cols => [ "Antibody" ],     :description => "Strain / Antibody" } ],
        [ :strain_vs_stage,             { :rows => [ "Strain" ],          :cols => [ "Stage" ],        :description => "Strain / Stage" } ]
      ],
      [ "Stage",
        [ :stage_vs_antibodies,         { :rows => [ "Stage" ],           :cols => [ "Antibody" ],     :description => "Stage / Antibody" } ],
      ],
      [ "Experiment Type",
        [ :experiment_type_vs_stage,    { :rows => [ "Assay" ],           :cols => [ "Stage", "Stage/Treatment" ],        :description => "Experiment Type / Stage" } ],
      ],
    ]
    @matrix_styles.extend(FancyGroupedOptions)

    # Matrix template info
    @selected_template = (params[:selected_template].nil? || params[:selected_template].empty?) ? nil : params[:selected_template]
    newest_dmelanogaster = @freeze_files.find { |ff| ff[0] == "D. melanogaster" }[1][0][1]
    newest_celegans = @freeze_files.find { |ff| ff[0] == "C. elegans" }[1][0][1]
    newest_combined = @freeze_files.find { |ff| ff[0] == "Combined" }[1][0][1]

    @template_styles = [
      [ "TF ChIP-chip",
        [ :tf_fly_chip_chip_of_cell_line_vs_antibodies,  { :matrix => :cell_line_vs_antibodies, :experiment_types => [ "ChIP-chip" ], :data_types => [ "chromatin" ], :description => "Fly ChIP-chip - Cell Line / Antibody",  :freeze => newest_dmelanogaster } ],
        [ :tf_fly_chip_chip_of_stage_vs_antibodies,      { :matrix => :stage_vs_antibodies,     :experiment_types => [ "ChIP-chip" ], :data_types => [ "chromatin" ], :description => "Fly ChIP-chip - Stage / Antibody",      :freeze => newest_dmelanogaster } ],
        [ :tf_worm_chip_chip_of_strain_vs_antibodies,    { :matrix => :strain_vs_antibodies,    :experiment_types => [ "ChIP-chip" ], :data_types => [ "chromatin" ], :description => "Worm ChIP-chip - Strain / Antibody",    :freeze => newest_celegans } ],
        [ :tf_worm_chip_chip_of_stage_vs_antibodies,     { :matrix => :stage_vs_antibodies,     :experiment_types => [ "ChIP-chip" ], :data_types => [ "chromatin" ], :description => "Worm ChIP-chip - Stage / Antibody",     :freeze => newest_celegans } ],
      ],
      [ "TF ChIP-seq",
        [ :tf_fly_chip_seq_of_cell_line_vs_antibodies,   { :matrix => :cell_line_vs_antibodies, :experiment_types => [ "ChIP-seq" ], :data_types => [ "chromatin" ], :description => "Fly ChIP-seq - Cell Line / Antibody",  :freeze => newest_dmelanogaster } ],
        [ :tf_fly_chip_seq_of_stage_vs_antibodies,       { :matrix => :stage_vs_antibodies,     :experiment_types => [ "ChIP-seq" ], :data_types => [ "chromatin" ], :description => "Fly ChIP-seq - Stage / Antibody",      :freeze => newest_dmelanogaster } ],
        [ :tf_worm_chip_seq_of_strain_vs_antibodies,     { :matrix => :strain_vs_antibodies,    :experiment_types => [ "ChIP-seq" ], :data_types => [ "chromatin" ], :description => "Worm ChIP-seq - Strain / Antibody",    :freeze => newest_celegans } ],
        [ :tf_worm_chip_seq_of_stage_vs_antibodies,      { :matrix => :stage_vs_antibodies,     :experiment_types => [ "ChIP-seq" ], :data_types => [ "chromatin" ], :description => "Worm ChIP-seq - Stage / Antibody",     :freeze => newest_celegans } ],
      ],
      [ "TF ChIP",
        [ :tf_fly_chip_of_cell_line_vs_antibodies,       { :matrix => :cell_line_vs_antibodies, :experiment_types => [ "ChIP-seq", "ChIP-chip" ], :data_types => [ "chromatin" ], :description => "Fly ChIP - Cell Line / Antibody",  :freeze => newest_dmelanogaster } ],
        [ :tf_fly_chip_of_stage_vs_antibodies,           { :matrix => :stage_vs_antibodies,     :experiment_types => [ "ChIP-seq", "ChIP-chip" ], :data_types => [ "chromatin" ], :description => "Fly ChIP - Stage / Antibody",      :freeze => newest_dmelanogaster } ],
        [ :tf_worm_chip_of_strain_vs_antibodies,         { :matrix => :strain_vs_antibodies,    :experiment_types => [ "ChIP-seq", "ChIP-chip" ], :data_types => [ "chromatin" ], :description => "Worm ChIP - Strain / Antibody",    :freeze => newest_celegans } ],
        [ :tf_worm_chip_of_stage_vs_antibodies,          { :matrix => :stage_vs_antibodies,     :experiment_types => [ "ChIP-seq", "ChIP-chip" ], :data_types => [ "chromatin" ], :description => "Worm ChIP - Stage / Antibody",     :freeze => newest_celegans } ],
      ],
      [ "Histone mark ChIP-chip",
        [ :hm_fly_chip_chip_of_cell_line_vs_antibodies,  { :matrix => :cell_line_vs_antibodies, :experiment_types => [ "ChIP-chip" ], :data_types => [ "chromatin modification" ], :description => "Fly ChIP-chip - Cell Line / Antibody",  :freeze => newest_dmelanogaster } ],
        [ :hm_fly_chip_chip_of_stage_vs_antibodies,      { :matrix => :stage_vs_antibodies,     :experiment_types => [ "ChIP-chip" ], :data_types => [ "chromatin modification" ], :description => "Fly ChIP-chip - Stage / Antibody",      :freeze => newest_dmelanogaster } ],
        [ :hm_worm_chip_chip_of_strain_vs_antibodies,    { :matrix => :strain_vs_antibodies,    :experiment_types => [ "ChIP-chip" ], :data_types => [ "chromatin modification" ], :description => "Worm ChIP-chip - Strain / Antibody",    :freeze => newest_celegans } ],
        [ :hm_worm_chip_chip_of_stage_vs_antibodies,     { :matrix => :stage_vs_antibodies,     :experiment_types => [ "ChIP-chip" ], :data_types => [ "chromatin modification" ], :description => "Worm ChIP-chip - Stage / Antibody",     :freeze => newest_celegans } ],
      ],
      [ "Histone mark ChIP-seq",
        [ :hm_fly_chip_seq_of_cell_line_vs_antibodies,   { :matrix => :cell_line_vs_antibodies, :experiment_types => [ "ChIP-seq" ], :data_types => [ "chromatin modification" ], :description => "Fly ChIP-seq - Cell Line / Antibody",  :freeze => newest_dmelanogaster } ],
        [ :hm_fly_chip_seq_of_stage_vs_antibodies,       { :matrix => :stage_vs_antibodies,     :experiment_types => [ "ChIP-seq" ], :data_types => [ "chromatin modification" ], :description => "Fly ChIP-seq - Stage / Antibody",      :freeze => newest_dmelanogaster } ],
        [ :hm_worm_chip_seq_of_strain_vs_antibodies,     { :matrix => :strain_vs_antibodies,    :experiment_types => [ "ChIP-seq" ], :data_types => [ "chromatin modification" ], :description => "Worm ChIP-seq - Strain / Antibody",    :freeze => newest_celegans } ],
        [ :hm_worm_chip_seq_of_stage_vs_antibodies,      { :matrix => :stage_vs_antibodies,     :experiment_types => [ "ChIP-seq" ], :data_types => [ "chromatin modification" ], :description => "Worm ChIP-seq - Stage / Antibody",     :freeze => newest_celegans } ],
      ],
      [ "Histone mark ChIP",
        [ :hm_fly_chip_of_cell_line_vs_antibodies,       { :matrix => :cell_line_vs_antibodies, :experiment_types => [ "ChIP-seq", "ChIP-chip" ], :data_types => [ "chromatin modification" ], :description => "Fly ChIP - Cell Line / Antibody",  :freeze => newest_dmelanogaster } ],
        [ :hm_fly_chip_of_stage_vs_antibodies,           { :matrix => :stage_vs_antibodies,     :experiment_types => [ "ChIP-seq", "ChIP-chip" ], :data_types => [ "chromatin modification" ], :description => "Fly ChIP - Stage / Antibody",      :freeze => newest_dmelanogaster } ],
        [ :hm_worm_chip_of_strain_vs_antibodies,         { :matrix => :strain_vs_antibodies,    :experiment_types => [ "ChIP-seq", "ChIP-chip" ], :data_types => [ "chromatin modification" ], :description => "Worm ChIP - Strain / Antibody",    :freeze => newest_celegans } ],
        [ :hm_worm_chip_of_stage_vs_antibodies,          { :matrix => :stage_vs_antibodies,     :experiment_types => [ "ChIP-seq", "ChIP-chip" ], :data_types => [ "chromatin modification" ], :description => "Worm ChIP - Stage / Antibody",     :freeze => newest_celegans } ],
      ],
      [ "Transcription",
        [ :fly_rna_seq_of_strain_vs_stage,               { :matrix => :strain_vs_stage,          :experiment_types => [ "RNA-seq" ], :description => "Fly RNA-seq - Strain / Stage",  :freeze => newest_dmelanogaster } ],
        [ :worm_rna_seq_of_strain_vs_stage,              { :matrix => :strain_vs_stage,          :experiment_types => [ "RNA-seq" ], :description => "Worm RNA-seq - Strain / Stage", :freeze => newest_celegans } ],
        [ :fly_transcription_by_stage,                   { :matrix => :experiment_type_vs_stage, :experiment_types => [ "RNA-seq", "tiling array: RNA", "RACE", "CAGE", "RTPCR" ], :description => "Fly Transcription by Stage",  :freeze => newest_dmelanogaster } ],
        [ :worm_transcription_by_stage,                  { :matrix => :experiment_type_vs_stage, :experiment_types => [ "RNA-seq", "tiling array: RNA", "RACE", "CAGE", "RTPCR" ], :description => "Worm Transcription by Stage", :freeze => newest_celegans } ],
      ],
    ]
    @template_styles.extend(FancyGroupedOptions)

    # Custom matrix dimensions (for Advanced tab)
    @custom_col_types = [ "Compound", "Cell Line", "Strain", ["Stage", "Stage/Treatment"], "Tissue", "Antibody", "Organism", "Assay" ]
    @custom_row_types = @custom_col_types
    @custom_group_by_types = [ ["None", ""], "Cell Line", "Strain", ["Stage", "Stage/Treatment"], "Tissue", "Antibody", "Organism", "Assay" ]
    @custom_split_by_types = [ ["None", ""], "Organism", "Assay" ]

    if (@selected_freeze_id && (@selected_freeze_id != @prev_selected_freeze && !@prev_selected_freeze.nil?)) then
      # Clear filter options if we changed freezes
      @filter_options = HashWithIndifferentAccess.new
    elsif params[:filter]
      # Set filter options from params
      @filter_options = HashWithIndifferentAccess.new(params[:filter])
    elsif @selected_template
      @filter_options = HashWithIndifferentAccess.new(@template_styles.get(@selected_template))
      @selected_freeze_id = (@selected_freeze_id.nil? || @selected_freeze_id == "") ? @filter_options.delete(:freeze) : @selected_freeze_id
      @selected_matrix_style = @filter_options.delete(:matrix)
      @selected_freeze_files = just_filenames.find_all { |fname| fname == @selected_freeze_id }.map { |fname| 
        if fname =~ /^combined_/ then
          date = fname.match(/^combined_(.*)/)[1]
          [ "dmelanogaster_#{date}", "celegans_#{date}" ]
        else
          fname
        end
      }.flatten
      @freeze_data = get_freeze_data(@selected_freeze_files)
    else
      # New visit to the page
      @filter_options = HashWithIndifferentAccess.new
    end

    @param_to_name = {
      :experiment_types => { :select => "Select experiment type", :title => "Experiment Type" },
      :data_types       => { :select => "Select data type",       :title => "Data Type" },
      :projects         => { :select => "Project",                :title => "Project" },
      :labs             => { :select => "Lab",                    :title => "Lab" },
      :tissues          => { :select => "Tissue",                 :title => "Tissue" },
      :strains          => { :select => "Strain",                 :title => "Strain" },
      :cell_lines       => { :select => "Cell Line",              :title => "Cell Line" },
      :stages           => { :select => "Stage",                  :title => "Stage" },
      :antibodies       => { :select => "Antibody",               :title => "Antibody" },
      :array_platforms  => { :select => "Array Platform",         :title => "Array Platform" },
      :rnai_targets     => { :select => "RNAi Target",            :title => "RNAi Target" },
      :compounds        => { :select => "Compound",               :title => "Compound" }
    }

    @all_options = HashWithIndifferentAccess.new
    @all_options[:experiment_types] = @freeze_data.map { |project_info| project_info["Assay"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @all_options[:data_types]       = @freeze_data.map { |project_info| project_info["Data Type"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @all_options[:tissues]          = @freeze_data.map { |project_info| project_info["Tissue"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @all_options[:strains]          = @freeze_data.map { |project_info| project_info["Strain"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @all_options[:cell_lines]       = @freeze_data.map { |project_info| project_info["Cell Line"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @all_options[:antibodies]       = ((@freeze_data.size > 0 ? ["N/A"] : []) + @freeze_data.map { |project_info| project_info[:antibodies] }.flatten).uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @all_options[:array_platforms]  = ((@freeze_data.size > 0 ? ["N/A"] : []) + @freeze_data.map { |project_info| project_info[:array_platforms] }.flatten).uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @all_options[:compounds]        = ((@freeze_data.size > 0 ? ["N/A"] : []) + @freeze_data.map { |project_info| project_info[:compounds] }.flatten).uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @all_options[:rnai_targets]     = ((@freeze_data.size > 0 ? ["N/A"] : []) + @freeze_data.map { |project_info| project_info[:rnai_targets] }.flatten).uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @all_options[:stages]           = ((@freeze_data.size > 0 ? ["N/A"] : []) + @freeze_data.map { |project_info| project_info[:stages] }.flatten).uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @all_options[:projects]         = @freeze_data.map { |project_info| project_info["Project"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @all_options[:labs]             = @freeze_data.map { |project_info| project_info["Lab"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }

    # If any filters are empty, set them to include everything
    @all_options.each_key { |key| 
      @filter_options[key] = @all_options[key] if @filter_options[key].nil?
    }

    # Generate reduced set of params leaving out any options that include everything (for bookmarking)
    @reduced_params = HashWithIndifferentAccess.new(@filter_options)
    @reduced_params.delete_if { |key, value| @all_options[key] == value }

    # Include N/A columns?
    @include_na_columns = params[:include_na_columns].nil? ? false : true

    # Submit the form once
    @show_matrix = true if params[:show_matrix] == "true"

  end
  def index_freeze_data(freeze_data)
    index = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = Array.new } }
    idx2 = {}
    keys = freeze_data.map { |e| e.keys }.flatten.uniq
    freeze_data.each_index { |i|
      freeze_data[i][:idx] = i
      keys.each { |key|
        vals = freeze_data[i][key]
        if vals.nil? then
          index[key][nil].push i
        else
          vals.each { |val|
            val.split(/,\s*/).each { |splitval|
              index[key][splitval].push i
            }
          }
        end
        index[:id][i] = [i]
      }
    }
    return index
  end
end
