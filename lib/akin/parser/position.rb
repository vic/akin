module Akin
  module Parser
    class CharPosition
      attr_reader :line, :column, :index

      def self.zero
        new 0, 0, 0
      end

      def self.default
        new 1, 1, 1
      end

      def initialize(line, column, index)
        @line = line
        @column = column
        @index = index
      end

      def incr(*a)
        clone.incr!(*a)
      end

      def incr!(line = 0, column = 1, index = 1)
        line += @line
        index += @index
        if column.nil?
          column = CharPosition.default.column
        else
          column += @column
        end
        @line, @column, @index = line, column, index
        self
      end

      def pos
        [line, column, index]
      end

      def clone
        self.class.new(line, column, index)
      end
    end

    class FilePosition
      attr_accessor :logical, :physical, :filename

      def self.from(filename, line, column, index)
        new filename, CharPosition.new(line, column, index)
      end

      def initialize(filename, logical = CharPosition.default, physical = logical.clone)
        @filename = filename
        @logical = logical
        @physical = physical
      end

      def clone
        self.class.new(@filename, logical.clone, physical.clone)
      end

      def forward_char
        self.class.new(@filename, logical.incr, physical.incr)
      end

      def forward_line
        self.class.new(@filename, logical.incr(1, nil), physical.incr(1, nil))
      end

      def forward_esc_line
        self.class.new(@filename, logical.incr(0, 1), physical.incr(1, nil))
      end
    end
  end
end
