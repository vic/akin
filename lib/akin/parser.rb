module Akin

  module Parser

    BRACES_ALIST = [
                    ['(', ')'],
                    ['{', '}'],
                    ['[', ']'],
                    ['\(', '\)'],
                    ['\{', '\}'],
                    ['\[', '\]']
                   ]

    def braces
      @braces ||= BRACES_ALIST.dup
    end

    def brace(text)
      braces.assoc(text) || braces.rassoc(text)
    end

    def node(*a, &b)
      Node.new(*a, &b)
    end

    alias_method :n, :node

    def current_position(o = pos)
      Position.new(current_line(o), current_column(o))
    end

    def h
      Position.new(0, 0)
    end

    class Position
      attr_accessor :line, :column

      def initialize(line = nil, column = nil)
        @line, @column = line, column
      end

      def |(other)
        if @line.nil? || @line.zero?
          other
        else
          self
        end
      end

      def incr(line = 0, column = 1)
        self.class.new @line + line, @column + column
      end

      def at(line = 0, column = 0)
        self.class.new line, column
      end
    end

    class Node
      def initialize(position = Position.new, name = nil, *args)
        @pos, @name, @args = position, name, args
      end

      attr_reader :pos, :name, :args

      def first
        @args.first
      end

      def last
        @args.last
      end

      def [](idx)
        @args[idx]
      end

      def sexp
        sexp = []
        sexp << name if name
        sexp.push *args.map { |a| a.respond_to?(:sexp) && a.sexp || a }
        sexp
      end

      def with(name = nil, *args)
        self.class.new pos, name || @name, *args
      end

      def shuffle
        Shuffle.shuffle(self)
      end
    end

    def text_node(p, parts)
      parts = parts.compact
      return node(p, :text, "") if parts.empty?
      ary = parts.dup
      m = ary.shift
      if ary.empty?
        unless m.name == :text
          m = node(p, :chain, m, n(p, :name, "to_s"))
        end
        return m
      end
      node(p, :chain, m, *ary.map { |a| [n(p, :oper, "++"), a] }.flatten)
    end

    def chain_cont(a, b)
      if b.name == :chain
        if a.name == :chain
          a.args.push *b.args; a
        else
          n(a.pos, :chain, a, *b.args)
        end
      else
        n(a.pos, :chain, a, b)
      end
    end

  end # Parser

end
