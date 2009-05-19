
class Tryouts::Drill
  # = Response
  #
  # A generic base class for Dream and Reality
  #
  class Response < Struct.new(:rcode, :output, :emsg)
    def ==(other)
      self.code == other.rcode &&
      self.output == other.output &&
      self.emsg == other.emsg
    end
  end


  # = Dream
  #
  # Contains the expected response of a Drill
  #
  class Dream < Tryouts::Drill::Response; end

  # = Reality 
  #
  # Contains the actual response of a Drill
  #
  class Reality < Tryouts::Drill::Response; end

end