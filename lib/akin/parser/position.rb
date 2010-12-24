module Akin
  module Parser
    class CharPosition
      attr_reader :line, :column, :index

      def self.zero
        @zero ||= new 0, 0, 0
      end

      def self.default
        @default ||= new 1, 1, 1
      end

      def initialize(line, column, index)
        @line = line
        @column = column
        @index = index
      end

      def incr(line = 0, column = 1, index = 1)
        line += @line
        index += @index
        if column < 0
          column = CharPosition.default.column
        else
          column += @column
        end
        self.class.new(line, column, index)
      end

      def pos
        [line, column, index]
      end

      def clone
        self.class.new(line, column, index)
      end
    end

    class FilePosition
      attr_reader :logical, :physical, :filename

      def self.from(filename, line, column, index)
        new filename, CharPosition.new(line, column, index)
      end

      def initialize(filename, logical, physical = logical)
        @filename = filename
        @logical = logical
        @physical = physical
      end

      def clone
        self.class.new(@filename, logical, physical)
      end

      def forward_char
        self.class.new(@filename, logical.incr)
      end

      def forward_line
        self.class.new(@filename, logical.incr(1, -1))
      end

      def forward_esc_line(inc = 1)
        self.class.new(@filename, logical.incr(1, -1), physical.incr(0, inc))
      end
    end
  end
end
