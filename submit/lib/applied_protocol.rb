class AppliedProtocol
  def initialize(attrs = {})
    @inputs = Array.new
    @outputs = Array.new
    @protocols = Array.new
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

  def outputs=(newoutputs)
    @outputs = newoutputs
  end
  def outputs
    @outputs
  end

  def column=(newcolumn)
    @column = newcolumn
  end
  def column
    @column
  end

  def add_protocol(newprotocol)
    unless @protocols.include?(newprotocol)
      @protocols.push newprotocol
    end
  end
  def protocols
    @protocols
  end
  def protocols=(newprotocols)
    @protocols = newprotocols
  end

end

