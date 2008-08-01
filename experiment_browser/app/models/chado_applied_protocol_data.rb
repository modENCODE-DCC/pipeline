module Chado
  class AppliedProtocolDatum < ChadoDb
    require 'chado_applied_protocol'
    require 'chado_datum'

    belongs_to :datum, :foreign_key => "data_id"
    belongs_to :applied_protocol

    set_table_name "applied_protocol_data"
    set_primary_key "applied_protocol_data_id"
  end
end
