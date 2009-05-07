# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # google_pie_chart, as found at http://hungrymachine.com/2008/2/16/simple-google-pie-chart-graph-in-rails
  # Usage:
  # <%=google_pie_chart([["Very Liberal", 8], ["Liberal", 22], ["Moderate", 9], ["Conservative", 4], ["Very Conservative", 1]], :width => 626, :height => 300) %>

  def google_horiz_bar_chart(d, options = {})
    options[:width] ||= 300
    options[:height] ||= "#{options[:data].length*30+60}"
    options[:title] ||= "no title provided"
    options[:title] +="|(n=#{options[:data].map{|k,v| v}.sum})"
    options[:max] ||= [10,"#{options[:data].map{|k,v| v}.max}".to_i].max
    options[:min] ||= 0
    options[:xaxis] ||= [0,"#{options[:max]}".to_i/2,"#{options[:max]}".to_i]
    options[:chd] ||= "t:#{options[:data].map{|k,v|"#{v}"}.reverse.join(',')}"
    options[:chxl] ||=  "0:|#{options[:data].map{|k,v|"#{k}"}.join('|')}|1:|#{options[:xaxis].join('|')}"
   opts = {
      :cht => "bhs",
      #:chd => "t:#{options[:data].map{|k,v|"#{v}"}.reverse.join(',')}",
      :chd => options[:chd],
      :chtt => options[:title],
#      :chl => "#{data.map { |k,v| CGI::escape(k)}.join('|')}", #legend
      :chxt => "y,x", #order of data
      :chxl => options[:chxl],
      :chs => "#{options[:width]}x#{options[:height]}", #chart size
      :chxr => "1,0,options[:max]", #range 
      :chds => "#{options[:min]},#{options[:max]}",  #min & max
      :chco => "0000ff",  #color
    }
    image_tag("http://chart.apis.google.com/chart?#{opts.map{|k,v|"#{k}=#{v}"}.join('&')}", :style => "float: #{options[:align]}", :alt => "#{options[:title]}")
  rescue
  end

  def google_stacked_vert_bar_chart(d, options = {})

    options[:width] ||= [300,"#{options[:data].length*20}".to_i].max
    options[:height] ||= 250
    options[:title] ||= "no title provided"
    options[:show_legend] ||= false    
    options[:min] ||= 0
    options[:chxt] ||= "x,y"
    options[:color] ||=  "0000ff"
    options[:chbh] ||= "28,25,18"
    
  if (!options[:legend].nil?)
    #if we are given a legend, then we might have a stacked bar chart
    options[:chd] =  "t:#{options[:data].sort.map{|k,v| "#{v.join(',')}"}.join('|')}"
    sums = Hash.new {|k,v| k[v] = 0}
    options[:data].sort.each{|k,v| sums["#{k}"] = "#{v.sum}"}
    options[:chdl] = "#{sums.sort.map{|k,v| "#{k} (#{v})"}.join('|')}"
    options[:title] += "|(n=#{sums.map{|k,v| "#{v}".to_i}.sum})" unless options[:data].nil?    
    options[:max] ||= [10,"#{options[:data].map{|k,v| "#{v.max}".to_i}.sum}".to_i+1].max unless options[:data].nil?
    options[:xaxis] ||= [0,"#{options[:max]}".to_i/2,"#{options[:max]}".to_i]
    options[:chxl] = "0:|#{options[:legend].join('|')}|1:|#{options[:xaxis].join('|')}" 
    x=[]
    for i in 1..options[:legend].length do
      y = options[:data].sort.map{|k,v| v}.map{|a| a[i-1]}
      while (y.reverse.first==0) do
        y.reverse!.shift
	y.reverse!
      end
      x += ["t"+options[:data].sort.map{|k,v| "#{v[i-1]}".to_i}.sum.to_s+",000000,"+([y.length-1,0].max).to_s+",#{i-1},10"]
    end
    options[:chm] = x.join("|")

  end
   opts = {
      :cht => "bvs",
      :chd => options[:chd],
      :chtt => options[:title],
#      :chl => "#{data.map { |k,v| CGI::escape(k)}.join('|')}", #legend
      :chxt => options[:chxt], #order of data
      :chxl => options[:chxl],
      :chs => "#{options[:width]}x#{options[:height]}", #chart size
      :chxr => "1,0,#{options[:max]}", #range 
      :chds => "#{options[:min]},#{options[:max]}",  #min & max
      :chco => options[:color],  #color
      :chbh => options[:chbh],
      #:chdl => options[:chdl],
      :chm => options[:chm]
    }
    opts[:chdl] = options[:chdl] unless !options[:show_legend]

    image_tag("http://chart.apis.google.com/chart?#{opts.map{|k,v|"#{k}=#{v}"}.join('&')}", :style => "align: #{options[:align]}", :alt => "#{options[:title]}")
  rescue
    "An error occurred: #{CGI::escape($ERROR_INFO.inspect)}"

  end

  def google_vert_bar_chart(d, options = {})
    #assuming this is not actually a stacked chart!
    options[:width] ||= [300,"#{options[:data].length*20}".to_i].max
    options[:height] ||= 250
    options[:title] ||= "no title provided"
    
    options[:min] ||= 0
    options[:chxt] ||= "x,y"
    options[:color] ||=  "0000ff"
    options[:chbh] ||=  "28,25,18"
    x = []
    for i in 1..options[:data].length do
      x += ["t"+options[:data].map{|k,v| v}[i-1].to_s+",000000,0,#{i-1},10"]
    end
    options[:chm] = x.join("|")

    options[:max] ||= [10,"#{options[:data].map{|k,v| v}.max}".to_i].max+1 unless options[:data].nil?
    options[:xaxis] ||= [0,"#{options[:max]}".to_i/2,"#{options[:max]}".to_i]
    options[:chd] ||= "t:#{options[:data].map{|k,v|"#{v}"}.join(',')}"
    options[:chdl] ||= ""
    options[:chxl] ||=  "0:|#{options[:data].map{|k,v|"#{k}"}.join('|')}|1:|#{options[:xaxis].join('|')}"
    options[:title] += "|(n=#{options[:data].map{|k,v| v}.sum})" unless options[:data].nil?

   opts = {
      :cht => "bvs",
      :chd => options[:chd],
      :chtt => options[:title],
#      :chl => "#{data.map { |k,v| CGI::escape(k)}.join('|')}", #legend
      :chxt => options[:chxt], #order of data
      :chxl => options[:chxl],
      :chs => "#{options[:width]}x#{options[:height]}", #chart size
      :chxr => "1,0,options[:max]", #range 
      :chds => "#{options[:min]},#{options[:max]}",  #min & max
      :chco => options[:color],  #color
      :chbh => options[:chbh],
      :chm => options[:chm]

    }
    image_tag("http://chart.apis.google.com/chart?#{opts.map{|k,v|"#{k}=#{v}"}.join('&')}")
  rescue

    "An error occurred: #{CGI::escape($ERROR_INFO.inspect)}"
  end

  def google_scatter_plot(d, options = {})
    options[:width] ||= [300,"#{options[:data].length*20}".to_i].max
    options[:height] ||= 250
    options[:title] ||= "no title provided"    
    options[:min] ||= 0
    options[:chxt] ||= "x,y"
    options[:chls] ||= "0,0,0"   #no lines
    options[:color] ||=  "0066ff"
    options[:chm] = "o,#{options[:color]},0,-1.0,6"
    options[:max] ||= "#{options[:data].max}"
    #options[:xaxis] ||= [0,"#{options[:max]}".to_i/2,"#{options[:max]}".to_i]
    options[:chd] ||= "t:-1|#{options[:data].join(',')}"
    options[:chdl] ||= ""
    #options[:chxl] ||=  "#{options[:min]},#{options[:max]}"
    options[:title] += "|(n=#{options[:data].length})" unless options[:data].nil?

   opts = {
      :cht => "lxy",
      :chd => options[:chd],
      :chtt => options[:title],
#      :chl => "#{data.map { |k,v| CGI::escape(k)}.join('|')}", #legend
      :chxt => options[:chxt], #order of data
      #:chxl => options[:chxl],
      :chs => "#{options[:width]}x#{options[:height]}", #chart size
      :chxr => "0,0,#{options[:data].length}|1,0,#{options[:max]}", #range 
      :chds => "#{options[:min]},#{options[:max]}",  #min & max
      :chco => options[:color],  #color
      #:chbh => options[:chbh],
      :chm => options[:chm],
      :chls => "0,0,0"
    }
    url = "http://chart.apis.google.com/chart?#{opts.map{|k,v|"#{k}=#{v}"}.join('&')}"
    image_tag(url)

  rescue

    "An error occurred: #{CGI::escape($ERROR_INFO.inspect)}"
  end

  def google_scatter_plot_xy(d, options = {})
    options[:width] ||= [300,"#{options[:data].length*20}".to_i].max
    options[:height] ||= 250
    options[:title] ||= "no title provided"    
    options[:min] ||= 0
    options[:chxt] ||= "x,y"
    options[:chls] ||= "0,0,0"   #no lines
    options[:color] ||=  "0066ff"
    options[:chm] = "o,#{options[:color]},0,-1.0,6"
    options[:max] ||= "#{options[:data].max}"
    #options[:xaxis] ||= [0,"#{options[:max]}".to_i/2,"#{options[:max]}".to_i]
    options[:chd] ||= "t:#{options[:data].sort.map{|data| data[0]}.join(',')}|#{options[:data].sort.map{|data| data[1]}.join(',')}"
    options[:chdl] ||= ""
    #options[:chxl] ||=  "#{options[:min]},#{options[:max]}"
    options[:title] += "|(n=#{options[:data].length})" unless options[:data].nil?

   opts = {
      :cht => "s",
      :chd => options[:chd],
      :chtt => options[:title],
#      :chl => "#{data.map { |k,v| CGI::escape(k)}.join('|')}", #legend
      :chxt => options[:chxt], #order of data
      #:chxl => options[:chxl],
      :chs => "#{options[:width]}x#{options[:height]}", #chart size
      :chxr => "0,0,#{options[:data].sort.map{|data| data[0]}.max}|1,0,#{options[:data].sort.map{|data| data[1]}.max}", #range 
      :chds => "#{options[:min]},#{options[:max]}",  #min & max
      :chco => options[:color],  #color
      #:chbh => options[:chbh],
      :chm => options[:chm],
      :chls => "0,0,0"
    }
    url = "http://chart.apis.google.com/chart?#{opts.map{|k,v|"#{k}=#{v}"}.join('&')}"
    image_tag(url)

  rescue

    "An error occurred: #{CGI::escape($ERROR_INFO.inspect)}"
  end

  def google_pie_chart(data, options = {})
    options[:width] ||= 250
    options[:height] ||= 100
    options[:colors] = %w(0DB2AC F5DD7E FC8D4D FC694D FABA32 704948 968144 C08FBC ADD97E)
    dt = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-."
    options[:divisor] ||= 1

    while (data.map { |k,v| v }.max / options[:divisor] >= 4096) do
      options[:divisor] *= 10
    end

    opts = {
      :cht => options[:cht] || "p",
      :chd => "e:#{data.map{|k,v|v=v/options[:divisor];dt[v/64..v/64]+dt[v%64..v%64]}}",
      :chl => "#{data.map { |k,v| CGI::escape(k)}.join('|')}",
      :chs => "#{options[:width]}x#{options[:height]}",
      :chco => options[:colors].slice(0, data.length).join(','),
      :chtt => options[:chtt]
    }

    image_tag("http://chart.apis.google.com/chart?#{opts.map{|k,v|"#{k}=#{v}"}.join('&')}")
  rescue
  end

  # Usage: google_ometer_chart(value, { :min => ###, :max => ###, ... })
  def google_ometer_chart(value, options = {})
    options[:width] ||= 220
    options[:height] ||= 120
    options[:colors] ||= ['00ff00', 'ff0000']
    options[:min] ||= 0
    options[:max] ||= 100
    options[:chf] ||= 'a'
    options[:chl] ||= value

    opts = {
      :cht => "gom",
      :chl => options[:chl],
      :chs => "#{options[:width]}x#{options[:height]}",
      :chco => options[:colors].join(','),
      :chf => options[:chf],
      :chd => "t:#{value}",
      :chds => "#{options[:min]},#{options[:max]}"
    }
    image_tag("http://chart.apis.google.com/chart?#{opts.map{|k,v|"#{k}=#{v}"}.join('&')}")
  rescue
  end

  def free_space_for_files(files)
    df = `df -P`
    vols = Array.new
    df.to_a[1..-1].each do |line|
      vol = Hash.new
      (vol[:fs], vol[:size], vol[:used], vol[:avail], vol[:perc], vol[:mount]) = line.split(/\s+/)
      vol[:used_human] = vol[:used]
      if vol[:used_human].to_f >= (1024**2) then
        vol[:used_human] = "#{(vol[:used_human].to_f / 1024**2).round(1)}G"
      elsif vol[:used_human].to_f >= (1024) then
        vol[:used_human] = "#{(vol[:used_human].to_f / 1024).round(1)}M"
      else
        vol[:used_human] = vol[:used_human] + "K"
      end

      vol[:avail_human] = vol[:avail]
      if vol[:avail_human].to_f >= (1024**2) then
        vol[:avail_human] = "#{(vol[:avail_human].to_f / 1024**2).round(1)}G"
      elsif vol[:avail_human].to_f >= (1024) then
        vol[:avail_human] = "#{(vol[:avail_human].to_f / 1024).round(1)}M"
      else
        vol[:avail_human] = vol[:avail_human] + "K"
      end

      vols.push(vol)
    end
    vols.sort! { |a,b| a[:mount].length <=> b[:mount].length }

    uniq_vols = Array.new
    files.each do |file|
      vol_for_file = nil
      vols.each do |vol|
        vol_for_file = vol if file =~ Regexp.new("^#{Regexp.escape(vol[:mount])}")
      end
      uniq_vols.push vol_for_file unless vol_for_file.nil?
    end
    uniq_vols.uniq!
    uniq_vols
  end

  def get_cpu_usage_of_self
    `ps -u\`whoami\`  -o pcpu --no-header`.to_a.map { |pcpu| pcpu.to_f }.sum
  end

  def convert_time(time)
    converted = ""
    #converted = "#{time.round/86400}d:#{(time.round/360) % 24}h:#{(time.round / 60) % 60 }m:#{time.round % 60}s"
    converted = "#{time.round % 60}s"
    converted = "#{(time.round / 60) % 60 }m:"+converted unless (time.round/60) == 0 
    converted = "#{(time.round/3600) % 24}h:"+converted unless (time.round/3600) == 0
    converted = "#{time.round/86400}d:"+converted unless (time.round/86400) == 0
    #converted += "(#{time.round}) "
    converted
    rescue
      "there was an error"
  end


end
