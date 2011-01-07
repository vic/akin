module Akin
  module Parser
    Language.syntax = Syntax.define do

      a(:eof)             .is nil

      a(:dash)            .is "-"
      a(:slash)           .is "/"
      a(:underscore)      .is "_"
      a(:back_slash)      .is "\\"

      a(:unix_eol)        .is "\n"
      a(:win_eol)         .is "\r\n"
      a(:eol)             .is [:unix_eol, :win_eol]
      a(:escaped_eol)     .is :back_slash, :eol

      a(:eol).as NewLine
      a(:escaped_eol).as EscapedNewLine

      a(:line_comment)    .is "#", ["#", "!", " "], a(:eol).but.any

      a(:space).as(Space) .is a([/ \t/, :escaped_eol]).many

      a(:alpha)           .is /[a-zA-Z]/
      a(:bin_digit)       .is /[01]/
      a(:oct_digit)       .is /[0-7]/
      a(:hex_digit)       .is /[0-9a-fA-F]/
      a(:dec_digit)       .is /[0-9]/

      a(:digits).is do |digit|
        a(digit, a([ digit, a(:underscore, digit) ]).any)
      end

      a(:bin_int).as(Number/2)  .is "0", /[bB]/, a(:digits).of(:oct_digit)
      a(:oct_int).as(Number/8)  .is "0", a(/[oO]/).opt, a(:digits).of(:oct_digit)
      a(:dec_int).as(Number/10) .is a(:digits).of(:dec_digit)
      a(:hex_int).as(Number/16) .is "0", /[xX]/, a(:digits).of(:hex_digit)

      a(:integer).is [:bin_int, :hex_int, :oct_int, :dec_int]

    end
  end
end
