# require 'rubygems'
# require 'find'

class Workers

  PATH = "#{RAILS_ROOT}/config/workers.yml"

  ## A mini little worker....
  class Worker
    attr_reader :name, :ip, :disallowed_pis, :disallowed_users
    def initialize (name, ip, disallowed_pis, disallowed_users)
      @name = name
      @ip = ip
      @disallowed_pis = disallowed_pis
      @disallowed_users = disallowed_users
    end
  end

  ## Get 'em read.
  def self.get_workers

    all_workers = []
    if File.exists? PATH then
      workers_file = open(PATH) { |f| YAML.load(f.read) }
      workers_file['workers'].each do |w|
        all_workers.push(Worker.new(
          w['name'], 
          w["ip"],
          w["disallow_pis"] ? w["disallow_pis"].keys : [],
          w["disallow_users"] ? w["disallow_users"].keys : []
        ))
      end
    else
      raise Exception("You need a workers.yml file in your config/ directory to describe which workers are available to share the load.")
    end
    all_workers
  end
end
