module Akin
  module Shuffle
    extend self

    def shuffle(node)
      send "shuffle_#{node.name}", node
    end

    def nothing(node)
      node
    end

    alias_method :shuffle_name, :nothing
    alias_method :shuffle_text, :nothing
    alias_method :shuffle_fixnum, :nothing
    alias_method :shuffle_float, :nothing
    
  end
end
