module Akin
  module Parser
    module CharReader
      def self.from_string(str)
        StringCharReader.new(str)
      end

      class StringCharReader
        include CharReader

        attr_reader :index, :size

        def initialize(str)
          @buffer = str.dup.freeze
          @size = @buffer.size
          @index = 0
        end

        def read
          return if @index >= @size
          idx, @index = @index, @index + 1
          @buffer[idx,1]
        end
      end
    end
  end
end
