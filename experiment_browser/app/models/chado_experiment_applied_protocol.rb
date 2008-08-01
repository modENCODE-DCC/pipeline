module Chado
  class ExperimentAppliedProtocol < ChadoDb
    require 'chado_applied_protocol'
    require 'chado_experiment'
    belongs_to :experiment
    belongs_to :applied_protocol, :foreign_key => "first_applied_protocol_id"

    set_table_name "experiment_applied_protocol"
    set_primary_key "experiment_applied_protocol_id"
  end
end
