module Akin
  module Parser
    class Message < Struct.new(:type, :start, :end, :text)
    end

    class MessageReader
      def message(type, start, _end, text = text(start, _end))
        Message.new(type, start, _end, text)
      end

      def text(from, to)
        sb = ""
        while from != to
          sb << from.char unless from.escaped_eol?
          from = from.next
        end
        sb
      end

      def read_space(start)
        at = start
        while at.space?
          at = at.next
        end
        message(:space, start, at)
      end

      def read_identifier(start)
        at = start
        while !at.space?
          at = at.next
        end
        message(:identifier, start, at)
      end
    end
  end
end
