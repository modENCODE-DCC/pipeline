module Chado
  class Protocol < ChadoDb
    require 'chado_applied_protocol'
    require 'chado_attribute'
    has_many :applied_protocols
    has_and_belongs_to_many :chado_attributes, :join_table => :protocol_attribute, :class_name => "Attribute"

    set_table_name "protocol"
    set_primary_key "protocol_id"
  end
end
