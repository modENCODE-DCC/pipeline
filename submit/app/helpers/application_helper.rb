# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # google_pie_chart, as found at http://hungrymachine.com/2008/2/16/simple-google-pie-chart-graph-in-rails
  # Usage:
  # <%=google_pie_chart([["Very Liberal", 8], ["Liberal", 22], ["Moderate", 9], ["Conservative", 4], ["Very Conservative", 1]], :width => 626, :height => 300) %>

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

end
