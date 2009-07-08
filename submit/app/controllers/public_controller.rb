require 'open-uri'
require 'open3'
require 'find'
class PublicController < ApplicationController

  def index
    redirect_to :action => :list
  end

  def set_show_noreadme
    session[:show_noreadme] = params[:show_noreadme] == "true" ? true : false
    redirect_to :action => :list
  end

  def set_show_deprecated
    session[:show_deprecated] = params[:show_deprecated] == "true" ? true : false
    redirect_to :action => :list
  end

  def readme
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return false
    end
    @readme = @project.readme
  end

  def list
    @projects = Project.all
    @projects.delete_if { |p| p.deprecated? } unless session[:show_deprecated]
    @projects.delete_if { |p| !p.released? && !p.has_metadata? && !p.has_readme? } unless session[:show_noreadme]


    @modmine_ids = loaded_modmine_ids
    @modmine_link_template = modmine_link_template

    @organisms_by_pi = organisms_by_pi
    @viewer_lab = current_user ? nil : current_user.lab
    @pis = Project.all.map { |p| p.pi }.uniq
    if params[:sort] then
      session[:sort_list] = Hash.new unless session[:sort_list]
      params[:sort].each_pair { |column, direction| session[:sort_list][column] = [ direction, Time.now ] }
    end
    @new_sort_direction = Hash.new { |hash, column| hash[column] = 'forward' }
    if params[:sort] then
      session[:sort_list] = Hash.new unless session[:sort_list]
      params[:sort].each_pair { |column, direction| session[:sort_list][column] = [ direction, Time.now ] }
    end
    @new_sort_direction = Hash.new { |hash, column| hash[column] = 'forward' }
    if params[:pi] && params[:pi].length > 0 then
      if params[:pi] =~ /^All / then
        organism = params[:pi].match(/^All (.*)$/)[1]
        @projects.reject! { |p| 
          o = p.released_organism
          o = @organisms_by_pi[p.pi] if o.nil?
          o = "" if o.nil?
          organism.sub(/^(.).+ /, '\1. ').downcase != o.sub(/^(.).+ /, '\1. ').downcase
        }
      else
        @projects.reject! { |p| p.pi != params[:pi] }
      end
    end
    if session[:sort_list] then
      sorts = session[:sort_list].sort_by { |column, sortby| sortby[1] }.reverse.map { |column, sortby| column }
      @projects = @projects.sort { |p1, p2|
        p1_attrs = sorts.map { |col| (session[:sort_list][col][0] == 'backward') ?  p2.send(col) : p1.send(col) } << p1.id
        p2_attrs = sorts.map { |col| (session[:sort_list][col][0] == 'backward') ?  p1.send(col) : p2.send(col) } << p2.id
        p1_attrs.nil_flatten_compare p2_attrs
      }
      session[:sort_list].each_pair { |col, srtby| @new_sort_direction[col] = 'backward' if srtby[0] == 'forward' && sorts[0] == col }
    else
      @projects = @projects.sort { |p1, p2| p2.id <=> p1.id }
    end

    respond_to do |format|
      format.html {
        if params[:page_size] then
          begin
            session[:public_list_page_size] = params[:page_size].to_i
          rescue
          end
        end
        session[:public_list_page_size] = 25 if session[:public_list_page_size].nil?
        page_size = session[:public_list_page_size]
        page_offset = 0
        if params[:page] then
          page_offset = [(params[:page].to_i-1), 0].max * page_size
        end
        page_end = (page_offset + page_size)
        @cur_page = (page_offset / page_size) + 1
        @num_pages = @projects.size / page_size
        @num_pages += 1 if @projects.size % page_size != 0
        @has_next_page = @cur_page != @num_pages
        @has_prev_page = @cur_page != 1
        @projects = @projects[page_offset...page_end]
      }
      format.xml {
        xml_objs = Project.all.map { |p| 
          full_path = "/" + File.join("extracted", "/#{p.id}.chadoxml")
          url = url_for(:action => :get_file, :id => p) + full_path
          { 
            :id => p.id,
            :pi => p.pi,
            :status => p.status,
            :deprecated => p.deprecated?,
            :replaced_by => p.deprecated? ? p.deprecated_by_project.id : nil,
            :name => p.name,
            :chadoxml => url 
          }
        }
        render :xml => xml_objs
      }
      format.text {
        text_objs = Project.all.map { |p| 
          full_path = "/" + File.join("extracted", "/#{p.id}.chadoxml")
          url = url_for(:action => :get_file, :id => p) + full_path
          [
            p.id,
            p.deprecated?,
            p.deprecated? ? p.deprecated_by_project.id : nil,
            url,
            p.name,
            p.pi,
            p.status
          ].join("\t")
        }
        render :text => text_objs.join("\n")
      }
    end
  end

  def get_gbrowse_stanzas
    config_text = ""

    begin
      project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return false
    end

    all_track_defs = Array.new
    released_configs = TrackStanza.find_all_by_project_id_and_released(params[:id], true)
    unless current_user == :false then
      all_track_defs = TrackStanza.find_all_by_project_id(current_user, params[:id])
    end
    released_configs.each { |td|
      all_track_defs.delete_if { |atd| atd.project_id == td.project_id }
      all_track_defs.push td
    }

    track_defs = Hash.new
    all_track_defs.each { |td| track_defs.merge! td.stanza }
    track_defs.delete_if { |stanzaname, definition| definition['key'].nil? }

#    track_defs.map { |stanzaname, definition| definition['database'] }.uniq.each do |database|
#      num = database.gsub(/^modencode_preview_/, '')
#      config_text << "[#{database}:database]\n"
#      config_text << "db_adaptor    = Bio::DB::SeqFeature::Store\n"
#      config_text << "db_args       = -adaptor DBI::Pg\n"
#      config_text << "                -dsn     dbname=modencode_gffdb;host=localhost\n"
#      config_text << "                -user    '????????'\n"
#      config_text << "                -pass    '????????'\n"
#      config_text << "\n"
#    end
    seen_dbs = Array.new
    track_defs.each do |stanzaname, definition| 
      database = definition['database'] 
      next if database.nil?
      next if seen_dbs.include?(database)
      if database =~ /^modencode_bam_/ then
        project_id = definition["data_source_id"]
        config_text << "[#{database}:database]\n"
        config_text << "db_adaptor    = Bio::DB::Sam\n"
        config_text << "db_args       = -fasta ???source_organism???.fa\n"
        config_text << "                -bam #{definition[:bam_file]}\n"
        config_text << "                -split_splices 1\n"
        config_text << "\n"
      else
        num = database.gsub(/^modencode_preview_/, '')
        config_text << "[#{database}:database]\n"
        config_text << "db_adaptor    = Bio::DB::SeqFeature::Store\n"
        config_text << "db_args       = -adaptor DBI::Pg\n"
        config_text << "                -dsn     dbname=modencode_gffdb;host=smaug.lbl.gov\n"
        config_text << "                -user    '?????????\n"
        config_text << "                -pass    '?????????\n"
        config_text << "                -schema  modencode_experiment_#{num}_data\n"
        config_text << "\n"
      end
    end

    track_defs.each do |stanzaname, definition|
      semantic_configs = definition[:semantic_zoom]

      config_text << "[#{stanzaname}]\n"
      definition.each do |option, value|
        next if option.is_a? Symbol
        next if value.nil?
        config_text << "#{option} = #{value.to_s.gsub("\n", "\n ")}\n"
      end
      config_text << "\n" if semantic_configs.size > 0
      semantic_configs.each do |zoom_level, zoom_definition|
        config_text << "[#{stanzaname}:#{zoom_level}]\n"
        zoom_definition.each do |option, value|
          next if option.is_a? Symbol
          next if value.nil?
          config_text << "#{option} = #{value.to_s.gsub("\n", "\n ")}\n"
        end
      end
      config_text << "\n\n\n"
    end
    if config_text.length > 0 then
      config_text = "# GBrowse stanza configuration for tracks generated\n# for project ##{project.id}: #{project.name}\n\n" + config_text
      send_data config_text, :type => "text/plain", :filename => "stanzas.txt", :disposition => "inline"
    else
      render :text => "No tracks configured for this project."
    end
  end

  def citation
    config_text = ""

    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return false
    end

    all_track_defs = Array.new
    released_configs = TrackStanza.find_all_by_project_id_and_released(params[:id], true)
    unless current_user == :false || released_configs.size > 0 then
      released_configs = TrackStanza.find_all_by_user_id_and_project_id(current_user.id, params[:id])
      @unreleased_config = true
    end
    @citations = Hash.new
    if released_configs.size > 0 then
      track_defs = released_configs.first.stanza
      track_defs.each { |stanzaname, definition|
        tracknum = definition["track_id"].to_i
        tracknum = definition["feature"].match(/.*:(\d+)(_details)?$/)[1].to_i unless tracknum
        citation = definition["citation"]
        @citations[citation] = Array.new unless @citations[citation]
        @citations[citation].push [ stanzaname, tracknum ]
      }
    end
  end

  def download_tarball
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    download_dir = ""
    download_dir = (params[:root] == "tracks") ? "tracks" : "extracted" if (params[:root] && params[:root].length > 0)
    @root = download_dir
    @root_directory = File.join(PipelineController.new.path_to_project_dir(@project), download_dir)

    unless File.directory?(@root_directory) then
      if @root.nil? || @root == "" then
        flash[:error] = "No data for this project."
        redirect_to :action => :list
      else
        flash[:warning] = "Data has not been extracted. Showing initial submission package."
        redirect_to :action => :download, :id => @project
      end
      return
    end

    @path = params[:path]
    @current_directory = @path ? File.expand_path(File.join(@root_directory, @path)) : @root_directory

    unless File.directory?(@current_directory) then
      flash[:warning] = "No data found in: #{@current_directory}"
      @current_directory = @root_directory
      redirect_to :action => :list
      return
    end
    unless @current_directory.index(@root_directory) == 0 then
      flash[:error] = "Invalid path"
      redirect_to :action => :download
      return
    end

    escape_quote = "'\\''"

    exclude = params[:include_chadoxml] == "true" ? '' : '--exclude \'*.chadoxml\''
    files = "'#{File.basename(@current_directory).gsub(/'/, escape_quote)}'"
    flatten = ''
    if params[:structured] != "true" then
      flatten = '--transform \'s/^\.\///g\'  --transform \'s/\//_/g\''
      files = "--files-from <( cd '#{File.dirname(@current_directory).gsub(/'/, escape_quote)}'; find './#{File.basename(@current_directory).gsub(/'/, escape_quote)}' -type f )"
    end
    command = "tar #{exclude} #{flatten} -czv -C '#{File.dirname(@current_directory).gsub(/'/, escape_quote)}' #{files}"

    headers['Content-Type'] = 'application/x-tar-gz'
    headers['Content-Disposition'] = "attachment; filename=#{File.basename(@current_directory)}.tgz"
    headers['Content-Transfer-Encoding'] = 'binary'

    render :status => 200, :text => Proc.new { |response, output|
      max_size = 4096
      Open3.popen3('bash', '-c', command) { |stdin, stdout, stderr|
        stderr_is_eof = false
        stdout_is_eof = false
        while !stderr_is_eof || !stdout_is_eof do
          begin
            string = stderr.read_nonblock(max_size)
          rescue EOFError
            stderr_is_eof = true
          rescue Errno::EAGAIN
          end
          buf = ""
          begin
            buf = stdout.read_nonblock(max_size)
          rescue EOFError
            stdout_is_eof = true
          rescue Errno::EAGAIN
          end
          output.write(buf) if buf.length > 0
        end
        output.flush
      }
    }
  end
  def download
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "list"
      return
    end
    download_dir = ""
    download_dir = (params[:root] == "tracks") ? "tracks" : "extracted" if (params[:root] && params[:root].length > 0)
    @root = download_dir
    @root_directory = File.join(PipelineController.new.path_to_project_dir(@project), download_dir)

    unless File.directory?(@root_directory) then
      if @root.nil? || @root == "" then
        flash[:error] = "No data for this project."
        redirect_to :action => :list
      else
        flash[:warning] = "Data has not been extracted. Showing initial submission package."
        redirect_to :action => :download, :id => @project
      end
      return
    end

    @path = params[:path]
    @current_directory = @path ? File.expand_path(File.join(@root_directory, @path)) : @root_directory

    unless File.directory?(@current_directory) then
      flash[:warning] = "No data found in: #{@current_directory}"
      @current_directory = @root_directory
      redirect_to :action => :list
    end
    unless @current_directory.index(@root_directory) == 0 then
      flash[:error] = "Invalid path"
      redirect_to :action => :download
    end

    if @current_directory != @root_directory then
      @parent = File.split(@current_directory)[0][@root_directory.length..-1]
    end

    @highlight = params[:highlight]

    @listing = Array.new
    Find.find(@current_directory) do |path|
      next if File.basename(path) == File.basename(@current_directory)
      relative_path = path[@root_directory.length..-1]
      if File.directory? path
        @listing.push [ :folder, relative_path, Array.new, 0 ]
        Find.prune
        next
      end
      size = File.size(path)
      if size.to_f >= (1024**2) then 
        size = "#{(size.to_f / 1024**2).round(1)}M"
      elsif size.to_f >= (1024) then
        size = "#{(size.to_f / 1024).round(1)}K"
      end
      @listing.push [ :file, relative_path, nil, size ]
    end
    @listing.sort! { |l1, l2| (l1[0] == :folder ? "0#{l1[1]}" : "1#{l1[1]}") <=> (l2[0] == :folder ? "0#{l2[1]}" : "1#{l2[1]}") }
    @listing.reject! { |l| !(l[1].include? @highlight) } if @highlight
  end

  def get_file
    begin
      @project = Project.find(params[:id])
    rescue
      flash[:error] = "Couldn't find project with ID #{params[:id]}"
      redirect_to :action => "download"
      return
    end

    # TODO: Make sure that this project is actually released
    download_dir = ""
    download_dir = (params[:root] == "tracks") ? "tracks" : "extracted" if (params[:root] && params[:root].length > 0)
    @root_directory = File.join(PipelineController.new.path_to_project_dir(@project), download_dir)

    file = File.expand_path(File.join(@root_directory, params[:path]))

    unless file.index(@root_directory) == 0 then
      # Doesn't seem to be in the root directory
      flash[:error] = "Invalid path"
      redirect_to :action => :download
      return
    end
    unless File.file?(file) then
      # Try to see if there's a base directory from the archive
      # (e.g. extracted/MySubmission/...)
      curdir = File.dirname(file)
      subdirs = Dir.entries(curdir).reject { |entry| entry =~ /^\./ }.find_all { |entry| File.directory?(File.join(curdir, entry)) }
      file = File.join(curdir, subdirs[0], File.basename(file)) if subdirs.size == 1
      unless File.file?(file) then
        flash[:error] = "File does not exist #{file}"
        redirect_to :action => :download, :id => params[:id], :root => params[:root] 
        return
      end
    end

    last_modified = File.mtime(file)
    headers['Last-Modified'] = last_modified.httpdate
    if request.env.include?('HTTP_IF_MODIFIED_SINCE') then
      since = Time.parse(request.env['HTTP_IF_MODIFIED_SINCE'])
      if since >= last_modified then
        render :nothing => true, :status => 304
        return
      end
    end

    type = case File.extname(file).sub(/^\./, '')
           when "gff"
             type = "text/plain"
           when "gff3"
             type = "text/plain"
           when "txt"
             type = "text/plain"
           when "idf"
             type = "text/plain"
           when "sdrf"
             type = "text/plain"
           when "chadoxml"
             type = "text/xml"
           else
             type = "application/octect-stream"
           end

    send_file file, { :disposition => 'attachment', :type => type, :filename => File.basename(file), :stream => true, :x_sendfile => true }
  end

  private

  def loaded_modmine_ids
      ids = Array.new
      loaded_ids_url = open("#{RAILS_ROOT}/config/modmine.yml") { |f| YAML.load(f.read) }["loaded_ids_url"]
      cache_file = open("#{RAILS_ROOT}/config/modmine.yml") { |f| YAML.load(f.read) }["cache_file"]
      cache_file = File.join(RAILS_ROOT, cache_file) unless (cache_file =~ /^\//)

      modtime = Time.new - 84001 # By default, it's out of date
      modtime = File.mtime(cache_file) if File.exists?(cache_file)
      if Time.new - modtime > 84000 then
        OpenURI.open_uri(loaded_ids_url) { |result|
          File.open(cache_file, "w") { |f| f.puts result.read }
        }
      end
      File.open(cache_file) { |f| ids = f.read.split.map { |n| n.to_i } }

      return ids
  end
  def modmine_link_template
    if File.exists? "#{RAILS_ROOT}/config/modmine.yml" then
      open("#{RAILS_ROOT}/config/modmine.yml") { |f| YAML.load(f.read) }["link_template"]
    else
      ""
    end
  end
  def organisms_by_pi
    if File.exists? "#{RAILS_ROOT}/config/pi_organisms.yml" then
      open("#{RAILS_ROOT}/config/pi_organisms.yml") { |f| YAML.load(f.read) }
    else
      {}
    end
  end

end

