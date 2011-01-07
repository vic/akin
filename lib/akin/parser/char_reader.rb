module Akin
  module Parser
    module CharReader
      def self.from_string(str)
        UnicodeCharReader.new(str)
      end

      def self.split(str)
        UnicodeCharReader.new(str).split
      end

      class UnicodeCharReader
        include CharReader

        attr_reader :index, :size, :char

        def initialize(str)
          @buffer = str.unpack('U*')
          @size = @buffer.size
          @index = 0
        end

        def split
          @buffer.map { |i| [i].pack('U*') }
        end

        def read
          return if @index >= @size
          idx, @index = @index, @index + 1
          @buffer[idx,1].pack('U*')
        end
      end
    end
  end
end
