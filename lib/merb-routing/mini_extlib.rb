# this provides a basic compatibility library to extlib
class Hash
  def only(*allowed)
    hash = {}
    allowed.each {|k| hash[k] = self[k] if self.has_key?(k) }
    hash
  end
end

module Extlib
  class Inflection
    def self.singularize(str)
      str.singularize
    end
  end
end

class String
  def to_const_string
    gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end
end

class Object
  def full_const_get(name)
    name.constantize
  end
end