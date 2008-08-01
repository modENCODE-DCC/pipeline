module Chado
  class Experiment < ChadoDb
    require 'chado_experiment_applied_protocol'
    require 'chado_applied_protocol'
    require 'chado_experiment_prop'
    has_many :experiment_applied_protocols
    has_many :applied_protocols, :through => :experiment_applied_protocols

    has_many :experiment_props

    set_table_name "experiment"
    set_primary_key "experiment_id"
  end
end
