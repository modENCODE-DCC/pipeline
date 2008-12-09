class AppliedProtocol
  def initialize(attrs = {})
    @inputs = Array.new
    attrs.each_pair { |key, value|
      m = self.method("#{key}=")
      m.call value unless m.nil?
    }
  end

  def applied_protocol_id=(id)
    @applied_protocol_id = id
  end
  def applied_protocol_id
    @applied_protocol_id
  end
  
  def inputs=(newinputs)
    @inputs = newinputs
  end
  def inputs
    @inputs
  end

  def protocol=(newprotocol)
    @protocol = newprotocol
  end
  def protocol
    @protocol
  end

  def column=(newcolumn)
    @column = newcolumn
  end
  def column
    @column
  end

end
