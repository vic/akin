module Akin
  module Parser
    module Syntax
      def self.define(mod = Module.new, &block)
        mod.extend ClassMethods
        mod.module_eval(&block)
        mod
      end

      module ClassMethods
        def a(*rest, &block)
          get = lambda { |name| @at[name] }
          if rest.size == 1 && Symbol === rest.first
            @at ||= Hash.new { |h,k| h[k] = Matcher.new(get).as(k) }
            @at[rest.first]
          else
            Matcher.new(get).is(*rest)
          end
        end
      end
    end

    module NewLine
      attr_reader :old_pos

      def fwd
        return @line_fwd if @line_fwd
        fwd = super
        if positive?
          pos = fwd.position
          @old_pos = pos.clone
          pos.logical.incr!(1, nil, 0)
          pos.physical.incr!(1, nil, 0)
        end
        @line_fwd = fwd
      end
    end

    module EscapedNewLine
      def eol
        self[1]
      end

      def unix?
        eol.name == :unix_eol
      end

      def char
        if positive?
          " "
        else
          super
        end
      end

      def fwd
        return @escaped_fwd if @escaped_fwd
        fwd = super
        if positive?
          n = if unix? then -1 else -2 end
          fwd.position.logical = eol.old_pos.logical.incr(0, n, n)
        end
        @escaped_fwd = fwd
      end
    end

    module Space
    end

    module Number
      def self./(base)
        Module.new do
          include Number
          define_method(:base) { base }
        end
      end

      def value
        text.to_i base
      end

      def text
        text = if base == 10 then super else self[2].text end
        text.gsub('_', '')
      end
    end

    module Language
      class << self
        attr_accessor :syntax
      end

      def parse(code)
      end
    end
  end
end
