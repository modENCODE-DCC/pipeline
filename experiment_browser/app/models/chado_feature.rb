module Chado
  class Feature < ChadoDb
    require 'chado_datum'
    has_and_belongs_to_many :data, :join_table => :data_feature, :association_foreign_key => "data_id"

    set_table_name "feature"
    set_primary_key "feature_id"
  end
end
