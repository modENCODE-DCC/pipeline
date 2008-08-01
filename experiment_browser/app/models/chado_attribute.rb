module Chado
  class Attribute < ChadoDb
    require 'chado_protocol'
    require 'chado_datum'
    require 'chado_type'
    has_and_belongs_to_many :protocols, :join_table => :protocol_attribute
    has_and_belongs_to_many :data, :join_table => :data_attribute, :association_foreign_key => "data_id"

    belongs_to :type

    set_table_name "attribute"
    set_primary_key "attribute_id"
  end
end
