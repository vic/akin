module Akin
  module Parser
    class MatchInput
      attr_accessor :position
      def initialize(char_reader, position)
        @char_reader, @position = char_reader, position
      end

      def char
        @char ||= @char_reader.read
      end

      def fwd
        @fwd ||= self.class.new(@char_reader, @position.forward_char)
      end

      def clone
        self.class.new(@char_reader, @position.clone)
      end
    end

    class Matcher

      [ :name, :mixin, :block, :seq, :min, :max, :pos, :true, :parse ].tap do |attrs|
        attr_reader *attrs

        define_method(:with) do |map|
          Matcher.new(@lookup).tap do |m|
            attrs.each do |key|
              ivar = "@#{key}"
              value = nil
              if map.key?(key)
                value = map[key]
              else
                value = instance_variable_get(ivar)
              end
              m.instance_variable_set("@#{key}", value)
            end
          end
        end
        private :with
      end

      def initialize(block)
        @lookup = block
        @true, @pos, @min, @max = true, true, 1, 1
      end

      def lookup(name)
        @lookup.call(name)
      end

      def but
        with :pos => !@pos
      end

      def not
        with :true => !@true
      end

      def one
        rep(1, 1)
      end

      def opt
        rep(0, 1)
      end

      def any
        rep(0, nil)
      end

      def many
        rep(1, nil)
      end

      def rep(min = 1, max = 1)
        with :min => min, :max => max
      end

      def as(name = nil, &block)
        @name = name if Symbol === name
        @mixin = name if Module === name
        (@mixin ||= Module.new).module_eval(&block) if block
        self
      end

      def is(*seq, &block)
        @block = block
        seq = block.call if block && block.arity == 0 && seq.empty?
        @seq = seq
        self
      end

      def of(*args)
        with :seq => block.call(*args)
      end

      def parse(&block)
        @parse = block
      end

      def match(input)
        min = @min; max = @max || Fixnum::MAX; seq = Array(@seq)
        raise "min and max should be positive numbers" if min < 0 || max < 0
        raise "max should be greater or equals than min" if max < min
        raise "nothing to match upon" if seq.empty?
        return @parse.call(input, seq, min, max) if @parse
        match_rep(input, seq, min, max)
      end

      def +(other)
        Matcher.new(@lookup).is(self, other)
      end

      def |(other)
        Matcher.new(@lookup).is [self,other]
      end

    private

      def positive?(bool)
        if @pos
          bool
        else
          !bool
        end
      end

      def match_positive(*a, &b)
        match_new(@true, *a, &b)
      end

      def match_negative(*a, &b)
        match_new(!@true, *a, &b)
      end

      def match_new(positive, from, to, fwd, &block)
        Match.new.tap do |m|
          m.name = self.name
          m.positive = positive
          m.from = from
          m.to = to
          m.fwd = fwd
          m.tap(&block) if block
          m.expected = self unless positive
        end
      end

      def match_rep(input, ary, min, max)
        m = match_all(input, ary)
        return m if min == max && min == 1
        if min == 0 && max == 0
          m.fwd = input
          m.positive = !m.positive?
          return m
        elsif min == 0 && max == 1
          m.positive = true
          return m
        end
        matches = []
        while m.positive? && matches.size <= max
          matches << m
          m = match_all(m.fwd, ary)
        end
        if matches.size < min
          match_negative(input, nil, input)
        elsif min == 0 && matches.empty?
          match_positive(input, nil, input)
        else
          match_positive(input, matches.last.to, matches.last.fwd) do |m|
            m.ary = matches
          end
        end
      end

      def match_all(input, ary)
        all, named = [], {}
        match, at = nil, input
        ary.each_with_index do |item, index|
          match = match_single(at, item)
          if @true && match.positive?
            at = match.fwd
            all << match
            named[match.name] = match if match.name
          else
            match.from = input
            return match
          end
        end
        if all.size == 1
          match = all.first
          match.extend @mixin if @mixin && match.positive? && @pos
        else
          match = match_positive(input, all.last.to, all.last.fwd) do |match|
            match.ary = all
            match.map = named
            match.extend @mixin if @mixin && @pos
          end
        end
        match
      end

      def match_any(input, ary)
        match = nil
        ary.find do |item|
          match = match_single(input, item)
          positive?(match.positive?)
        end
        match
      end

      def match_string(input, string)
        s = Akin::Parser::CharReader.split(string)
        last = nil
        s.inject(input) do |at, char|
          if positive?(char === at.char)
            last = at
            at.fwd
          else
            return match_negative(input, last, input)
          end
        end
        match_positive(input, last, last.fwd)
      end

      def match_regexp(input, regexp)
        if positive?(input.char =~ regexp)
          match_positive(input, input, input.fwd)
        else
          match_negative(input, nil, input)
        end
      end

      def match_hash(input, hash)
        raise "Expected hash with just one pair." unless hash.size == 1
        m = match_single(input, hash.values.first)
        m.name = hash.keys.first
        m
      end

      def match_single(input, rule)
        case rule
        when Symbol:
          lookup(rule).match(input)
        when Matcher:
          rule.match(input)
        when String:
          match_string(input, rule)
        when Regexp:
          match_regexp(input, rule)
        when Array:
          match_any(input, rule)
        when Hash:
          match_hash(input, rule)
        else
          raise "Dont know how to match #{rule}"
        end
      end
    end

    class Match
      include Enumerable

      attr_accessor :name, :from, :to, :fwd, :ary, :map, :positive, :expected

      def text
        buff = ""
        if ary
          buff = ary.map { |a| a.text }.join
        elsif
          at = from
          while at != fwd
            buff << at.char
            at = at.fwd
          end
        end
        buff
      end

      def positive?
        @positive
      end

      def negative?
        !positive?
      end

      def each(&block)
        @ary.each(&block) if @ary
      end

      def [](name)
        (@map && @map[name]) || (@ary && @ary[name])
      end
    end

  end
end
