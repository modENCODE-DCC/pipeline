module Chado
  class Type < ChadoDb
    has_one :data
    has_one :experiment_prop
    has_one :attribute

    set_table_name "cvterm"
    set_primary_key "cvterm_id"
  end
end
