module Chado
  class Datum < ChadoDb
    require 'chado_attribute'
    require 'chado_applied_protocol_data'
    require 'chado_feature'
    require 'chado_type'
    has_and_belongs_to_many :chado_attributes, :join_table => :data_attribute, :foreign_key => "data_id", :class_name => "Attribute"
    has_and_belongs_to_many :features, :join_table => :data_feature, :foreign_key => "data_id"

    has_many :applied_protocol_data, :foreign_key => "data_id"
    has_many :applied_protocols, :through => :applied_protocol_data

    belongs_to :type

    set_table_name "data"
    set_primary_key "data_id"
  end
end
