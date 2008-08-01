class ChadoDb < ActiveRecord::Base
  establish_connection "chado"
end
