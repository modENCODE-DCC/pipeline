module Chado
  class ExperimentProp < ChadoDb
    require 'chado_experiment'
    require 'chado_type'
    belongs_to :experiment

    belongs_to :type

    set_table_name 'experiment_prop'
    set_primary_key 'experiment_prop_id'
  end
end
