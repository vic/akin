# -*- coding: utf-8 -*-
module Akin
  module Parser
    class CharAt
      attr_accessor :position
      attr_writer :char, :fwd

      def self.from(char_reader, position)
        new(char_reader, position)
      end

      def initialize(char_reader, position)
        @char_reader = char_reader
        @position = position
      end

      def inspect
        "Character #{char.inspect} at #{position.physical.inspect}"
      end

      def char
        @char ||= @char_reader.read
      end

      # For internal use only!.
      def fwd
        return @fwd if @fwd
        char # make sure we have read the current char
        @fwd = self.class.new(@char_reader, position.forward_char)
      end

      def next
        return @next if @next
        @next = fwd
        if at_escaped_eol? && fwd.at_unix_eol?
          @next = fwd.fwd
          @next.position = position.forward_esc_line
        elsif at_escaped_eol? && fwd.at_win_eol?
          @next = fwd.fwd.fwd
          @next.position = position.forward_esc_line
        elsif at_win_eol?
          @next = fwd.fwd
          @next.position = position.forward_line
        elsif at_unix_eol?
          @next.position = position.forward_line
        end
        @next
      end

      def at?(*seq)
        seq.inject(self) do |at, thing|
          case thing
          when Symbol:
            at.send "at_#{thing}?"
          when Array:
            thing.any? { |s| at.at?(s) }
          when Proc:
            thing.call(at.char)
          else
            thing === at.char
          end or return false
          at.send :fwd
        end
        true
      end

      def self.at(name, *seq)
        define_method("at_#{name}?") { at?(*seq) }
        alias_method "#{name}?", "at_#{name}?"
      end

      at :eof,             nil
      at :tab,             "\t"
      at :space,           [/[ \t]/, :escaped_eol]

      at :escaped_eol,     "\\", :eol
      at :unix_eol,        "\n"
      at :win_eol,         "\r", "\n"
      at :eol,             [:unix_eol, :win_eol]

      at :dash,            "-"
      at :slash,           "/"
      at :back_slash,      "\\"
      at :underscore,      "_"

      at :bin_digit,       /[01]/
      at :oct_digit,       /[0-7]/
      at :hex_digit,       /[0-9a-fA-F]/
      at :dec_digit,       /[0-9]/

      at :line_comment,    "#", [ /[!\#]/, :space ]

    end

  end
end
