class ExperimentBrowserController < ApplicationController
  require 'chado_experiment'

  layout 'experiment_browser', :only => [ :index, :select_tracks ]

  # GET /experiment_browsers
  # GET /experiment_browsers.xml
  def index
    @experiments = Chado::Experiment.find(:all)
  end

  # GET /experiment_browsers/1
  # GET /experiment_browsers/1.xml
  def experiment
    @experiment = Chado::Experiment.find(params[:id])
    @use_rowspan = (params[:use_rowspan].nil? || "true".eql?(params[:use_rowspan])) ? true : false
    @protocol_names = [""]

    # Get list of all protocols used
    col = 0
    ap = @experiment.applied_protocols[0]
    if ap then
      loop do
        @protocol_names[col] = ap.protocol.name
        break unless ap.next_applied_protocols.size > 0
        ap = ap.next_applied_protocols[0]
        col += 1
      end
    end

    # Generate spreadsheet of all protocols
    max_rows = 0;
    @experiment.applied_protocols.each { |ap| max_rows += ap.max_expansion }
    @spreadsheet = Array.new(@protocol_names.size) { Array.new(max_rows, nil) }
    next_aps = @experiment.applied_protocols + [ nil ]
    col = 0
    next_row = Array.new(@spreadsheet.size, 0)
    while next_aps.size > 0 do
      ap = next_aps.shift
      if ap.nil? then
        col += 1
        next_aps.push nil if next_aps.size > 0
        next
      end
      row = next_row[col]
      next_row[col] = row + ap.max_expansion
      @spreadsheet[col][row] = { :rowspan => ap.max_expansion, :name => ap.id.to_s + ":" + ap.protocol.name[0..10] } if row
      next_aps += ap.next_applied_protocols
    end
    @spreadsheet = @spreadsheet.transpose

    render :partial => "experiment"
  end
  def applied_protocol_browser
    @next_applied_protocols = []
    @previous_applied_protocols = []
    @breadcrumbs = []
    if params[:experiment_id] then
      experiment = Chado::Experiment.find(params[:experiment_id])
      @next_applied_protocols = experiment.applied_protocols
    elsif params[:id] then
      @current_applied_protocol = Chado::AppliedProtocol.find(params[:id])
      @next_applied_protocols = @current_applied_protocol.next_applied_protocols if @current_applied_protocol
      @previous_applied_protocols = @current_applied_protocol.previous_applied_protocols if @current_applied_protocol

      former_aps = [ @current_applied_protocol ]
      while (former_aps.size > 0) do
        @breadcrumbs.unshift former_aps
        former_aps = former_aps.collect { |ap| ap.previous_applied_protocols }.flatten
      end
    end
    @no_wrap_applied_protocol_browser = params[:no_wrap_applied_protocol_browser].eql? "true"
    self.applied_protocol if @current_applied_protocol # Populate variables for the _applied_protocol template
  end
  def applied_protocol
    @applied_protocol = Chado::AppliedProtocol.find(params[:id])
    @input_data = @applied_protocol.applied_protocol_data.find_all { |apd| apd.direction.rstrip.eql? 'input' }.collect{|apd| apd.datum}
    @output_data = @applied_protocol.applied_protocol_data.find_all { |apd| apd.direction.rstrip.eql? 'output' }.collect{|apd| apd.datum}
    @no_wrap_applied_protocol = params[:no_wrap_applied_protocol].eql? "true"
    self.datum if params[:data_id]
  end
  def datum
    if params[:data_id] then
      @datum = Chado::Datum.find(params[:data_id]) if params[:data_id]
    elsif params[:id] then
      @datum = Chado::Datum.find(params[:id]) if params[:id]
    end
  end
  def select_tracks
    set_region
    @chromosomes = Chado::Feature.find_by_sql("SELECT f.* FROM feature f INNER JOIN cvterm cvt ON f.type_id = cvt.cvterm_id WHERE cvt.name = 'chromosome_arm'");
  end
  def set_region
    @chr = params[:chr] ? Chado::Feature.find(params[:chr]) : Chado::Feature.find_by_uniquename("3L")
    @fmin = params[:fmin] ? params[:fmin].to_i : 123000
    @fmax = params[:fmax] ? params[:fmax].to_i : 125000
  end

end
