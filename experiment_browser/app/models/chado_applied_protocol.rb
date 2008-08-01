module Chado
  class AppliedProtocol < ChadoDb
    require 'chado_experiment_applied_protocol'
    require 'chado_experiment'
    require 'chado_protocol'
    require 'chado_applied_protocol_data'
    require 'chado_datum'

    has_many :experiment_applied_protocols, :foreign_key => "first_applied_protocol_id"
    has_many :experiments, :through => :experiment_applied_protocols

    has_many :applied_protocol_data
    has_many :data, :through => :applied_protocol_data

    belongs_to :protocol

    set_table_name "applied_protocol"
    set_primary_key "applied_protocol_id"

    def next_applied_protocols
      output_data = self.applied_protocol_data.find_all { |apd| apd.direction.rstrip.eql? 'output' }.collect{|apd| apd.datum}
      applied_input_data = output_data.collect { |output_datum|
        output_datum.applied_protocol_data.find_all{|ap| ap.direction.rstrip.eql? "input"}
      }.flatten
      next_protocols = applied_input_data.collect {|applied_input_datum| applied_input_datum.applied_protocol}
    end
    def previous_applied_protocols
      input_data = self.applied_protocol_data.find_all { |apd| apd.direction.rstrip.eql? 'input' }.collect{|apd| apd.datum}
      applied_output_data = input_data.collect { |input_datum|
        input_datum.applied_protocol_data.find_all{|ap| ap.direction.rstrip.eql? "output"}
      }.flatten
      previous_protocols = applied_output_data.collect {|applied_output_datum| applied_output_datum.applied_protocol}
    end
    def max_expansion
      max = 0
      for next_ap in self.next_applied_protocols do
        max += next_ap.max_expansion
      end

      max = 1 if max == 0 # If there are no more applied protocols after this one

      return max
    end
  end
end
