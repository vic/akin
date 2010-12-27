module Akin
  module Parser
    class Error < StandardError
      def initialize(check, at, expected = true)
        @check = check
        @at = at
        @expected = expected
        msg = expected and "Expected " or "Do not expected "
        msg << check
        msg << " at "
        msg << at
        super(msg)
      end
    end

    class Message < Struct.new(:type, :start, :end, :data)
    end

    class MessageReader
      def message(type, start, _end, data = text(start, _end))
        Message.new(type, start, _end, data)
      end

      def check_not(type, at)
        raise Error.new(type, at, false) if at.at?(type)
      end

      def check(type, at)
        raise Error.new(type, at) unless at.at?(type)
      end

      def text(from, to)
        sb = ""
        while from != to
          sb << from.char
          from = from.next
        end
        sb
      end

      def read_space(start)
        check :space, at = start
        at = at.next while at.space?
        text = text(start, at).gsub("\\", "") # continue with escaped newline
        message(:space, start, at, text)
      end

      def read_identifier(start)
        check :identifier, at = start
        at = at.next while !at.space?
        message(:identifier, start, at)
      end

      def read_integer(type, start)
        digit = :"#{type}_digit"
        check digit, at = start
        loop do
          if at.at?(digit)
            at = at.next
          elsif at.underscore? && at.next.at?(digit)
            at = at.next.next
          else
            break
          end
        end
        text = text(start, at).gsub("_", "")
        message(:"#{type}_integer", start, at, text)
      end

      def read_decimal(start)
        int = read_integer(:dec, start)
        int.type = :decimal
        int
      end

      def read_binary(start)
        check "0", start
        check ["b", "B"], start.next
        int = read_integer(:bin, start.next.next)
        int.type = :binary
        int
      end

      def read_octal(start)
        check "0", start
        if start.next.at? ["o", "O"]
          at = start.next.next
        else
          at = start.next
        end
        int = read_integer(:oct, at)
        int.type = :octal
        int
      end

      def read_hexadecimal(start)
        check "0", start
        check ["x", "X"], start.next
        int = read_integer(:hex, start.next.next)
        int.type = :hexadecimal
        int
      end

    end
  end
end
