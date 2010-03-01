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
class BulkDownloadController < ApplicationController
  FREEZE_FILES = {
    "" => [ nil ],
    "D. melanogaster" => [
      [ "2009-10-19", "dmelanogaster_2009-10-19" ],
      [ "2009-11-04", "dmelanogaster_2009-11-04" ]
    ],
    "C. elegans" => [ ]
  }
  def index
    @freeze_files = get_freeze_files
    just_filenames = @freeze_files.values.map { |v| v.map { |v2| v2[1] unless v2.nil? } }.flatten.compact
    @freeze_file = params[:selected_freeze] if just_filenames.include?(params[:selected_freeze])
    @freeze_data = get_freeze_data(@freeze_file)

    if (@freeze_file == params[:prev_selected_freeze]) then
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
    end

    @selected_data = get_selected_freeze_data(@freeze_data, @experiment_type, @data_type, @tissue, @strain, @cell_line, @stage, @antibody, @array_platform, @project, @lab, @compound, @rnai_target)

    @experiment_types = @freeze_data.map { |project_info| project_info["Assay"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
#    @disabled_experiment_types = @experiment_types - visible_freeze_data.map { |project_info| project_info["Experiment Type"].split(/, /) }.flatten.uniq
#    @experiment_type -= @disabled_experiment_types unless @experiment_type.nil?
#    @experiment_type = @experiment_types - @disabled_experiment_types if (@experiment_type.nil? || @experiment_type.size == 0)
    @experiment_type = @experiment_types if (@experiment_type.nil? || @experiment_type.size == 0)

    @data_types = @freeze_data.map { |project_info| project_info["Data Type"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
#    @disabled_data_types = @data_types - visible_freeze_data.map { |project_info| project_info["Data Type"].split(/, /) }.flatten.uniq
#    @data_type -= @disabled_data_types unless @data_type.nil?
#    @data_type = @data_types - @disabled_data_types if (@data_type.nil? || @data_type.size == 0)
    @data_type = @data_types if (@data_type.nil? || @data_type.size == 0)

    @tissues = @freeze_data.map { |project_info| project_info["Tissue"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @tissue = @tissues if (@tissue.nil? || @tissue.size == 0)

    @strains = @freeze_data.map { |project_info| project_info["Strain"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @strain = @strains if (@strain.nil? || @strain.size == 0)

    @cell_lines = @freeze_data.map { |project_info| project_info["Cell Line"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @cell_line = @cell_lines if (@cell_line.nil? || @cell_line.size == 0)

    @stages = @freeze_data.map { |project_info| project_info["Stage/Treatment"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @stage = @stages if (@stage.nil? || @stage.size == 0)

    @antibodies = @freeze_data.map { |project_info| project_info["Antibody"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @antibody = @antibodies if (@antibody.nil? || @antibody.size == 0)

    @array_platforms = @freeze_data.map { |project_info| project_info["Platform"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @array_platform = @array_platforms if (@array_platform.nil? || @array_platform.size == 0)

    @projects = @freeze_data.map { |project_info| project_info["Project"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @project = @projects if (@project.nil? || @project.size == 0)

    @labs = @freeze_data.map { |project_info| project_info["Lab"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @lab = @labs if (@lab.nil? || @lab.size == 0)

    @compounds = @freeze_data.map { |project_info| project_info["Compound"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @compound = @compounds if (@compound.nil? || @compound.size == 0)

    @rnai_targets = @freeze_data.map { |project_info| project_info["RNAi Target"].split(/, /) }.flatten.uniq.sort { |a, b| a.sub(/^N\/A/, " ") <=> b.sub(/^N\/A/, " ") }
    @rnai_target = @rnai_targets if (@rnai_target.nil? || @rnai_target.size == 0)

    if (@freeze_file == params[:prev_selected_freeze]) then
      @reduced_params = params
      @reduced_params.delete(:selected_experiment_type) if @reduced_params[:selected_experiment_type] == @experiment_types
      @reduced_params.delete(:selected_data_type) if @reduced_params[:selected_data_type] == @data_types
      @reduced_params.delete(:selected_tissue) if @reduced_params[:selected_tissue] == @tissues
      @reduced_params.delete(:selected_strain) if @reduced_params[:selected_strain] == @strains
      @reduced_params.delete(:selected_cell_line) if @reduced_params[:selected_cell_line] == @cell_lines
      @reduced_params.delete(:selected_stage) if @reduced_params[:selected_stage] == @stages
      @reduced_params.delete(:selected_antibody) if @reduced_params[:selected_antibody] == @antibodies
      @reduced_params.delete(:selected_array_platform) if @reduced_params[:selected_array_platform] == @array_platforms
      @reduced_params.delete(:selected_project) if @reduced_params[:selected_project] == @projects
      @reduced_params.delete(:selected_lab) if @reduced_params[:selected_lab] == @labs
      @reduced_params.delete(:selected_compound) if @reduced_params[:selected_compound] == @compounds
      @reduced_params.delete(:selected_rnai_target) if @reduced_params[:selected_rnai_target] == @rnai_targets
    else
      @reduced_params = Hash.new
    end

    respond_to do |format|
      format.html {
      }
      format.xml {
        xml_obj = Array.new
        @selected_data.each { |project_info|
          xml_hash = Hash.new
          project_info.each { |k, v|
            xml_hash[k.gsub(/ /, "-")] = v
          }
          xml_hash["url"] = url_for(:controller => :public, :action => :download_tarball, :id => project_info["ID"], :structured => true)
          xml_obj.push xml_hash
        }
        render :xml => xml_obj
      }
    end
  end

private

  def get_freeze_files()
    freeze_files = Hash.new { |h, k| h[k] = Array.new }
    freeze_files[""] = [ nil ]
    freeze_dir = "#{RAILS_ROOT}/config/freeze_data/"
    if File.directory? freeze_dir then
      Dir.glob(File.join(freeze_dir, "*.csv")).each { |f| 
        fname = File.basename(f)[0..-5]
        (organism, date) = fname.split(/_/)
        organism = organism[0..0].upcase + ". " + organism[1..-1]
        freeze_files[organism].push [ date, fname ]
      }
    end
    freeze_files.values.each { |dates| dates.sort! { |d1, d2| Date.parse(d2[0]) <=> Date.parse(d1[0]) }; dates.first[0] += " (newest)" if dates.first }
    return freeze_files
  end
  def get_freeze_data(freeze_file)
    data = Array.new
    if File.exists? "#{RAILS_ROOT}/config/freeze_data/#{freeze_file}.csv" then
      File.open("#{RAILS_ROOT}/config/freeze_data/#{freeze_file}.csv") { |f|
        headers = f.gets.chomp.split(/\t/)
        while ((line = f.gets) != nil) do
          fields = line.chomp.split(/\t/).map { |field| (field == "" ? "N/A" : field) }
          d = Hash.new; headers.each_index { |n| d[headers[n]] = fields[n] }
          data.push d
        end
      }
    end
    return data
  end

  def get_selected_freeze_data(freeze_data, experiment_type, data_type, tissue, strain, cell_line, stage, antibody, array_platform, project, lab, compound, rnai_target)
    freeze_data = freeze_data.reject { |project_info| (experiment_type & project_info["Assay"].split(/, /)).size == 0 } unless (experiment_type.nil? || experiment_type.size == 0)
    freeze_data = freeze_data.reject { |project_info| (data_type & project_info["Data Type"].split(/, /)).size == 0 } unless (data_type.nil? || data_type.size == 0)
    freeze_data = freeze_data.reject { |project_info| (tissue & project_info["Tissue"].split(/, /)).size == 0 } unless (tissue.nil? || tissue.size == 0)
    freeze_data = freeze_data.reject { |project_info| (strain & project_info["Strain"].split(/, /)).size == 0 } unless (strain.nil? || strain.size == 0)
    freeze_data = freeze_data.reject { |project_info| (cell_line & project_info["Cell Line"].split(/, /)).size == 0 } unless (cell_line.nil? || cell_line.size == 0)
    freeze_data = freeze_data.reject { |project_info| (stage & project_info["Stage/Treatment"].split(/, /)).size == 0 } unless (stage.nil? || stage.size == 0)
    freeze_data = freeze_data.reject { |project_info| (antibody & project_info["Antibody"].split(/, /)).size == 0 } unless (antibody.nil? || antibody.size == 0)
    freeze_data = freeze_data.reject { |project_info| (array_platform & project_info["Platform"].split(/, /)).size == 0 } unless (array_platform.nil? || array_platform.size == 0)
    freeze_data = freeze_data.reject { |project_info| (project & project_info["Project"].split(/, /)).size == 0 } unless (project.nil? || project.size == 0)
    freeze_data = freeze_data.reject { |project_info| (lab & project_info["Lab"].split(/, /)).size == 0 } unless (lab.nil? || lab.size == 0)
    freeze_data = freeze_data.reject { |project_info| (compound & project_info["Compound"].split(/, /)).size == 0 } unless (compound.nil? || compound.size == 0)
    freeze_data = freeze_data.reject { |project_info| (rnai_target & project_info["RNAi Target"].split(/, /)).size == 0 } unless (rnai_target.nil? || rnai_target.size == 0)

    return freeze_data
  end
end
