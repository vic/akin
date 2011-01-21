module Akin
  module Parser
    Language.syntax = Syntax.define do

      a(:eof)             .is nil
      a(:any)             .is /./

      a(:dollar)          .is "$"
      a(:dash)            .is "-"
      a(:slash)           .is "/"
      a(:underscore)      .is "_"
      a(:back_slash)      .is "\\"
      a(:dot)             .is "."
      a(:comma)           .is ","
      a(:collon)          .is ":"
      a(:semicollon)      .is ";"

      a(:unix_eol)        .is "\n"
      a(:win_eol)         .is "\r\n"
      a(:eol)             .is [:unix_eol, :win_eol]
      a(:escaped_eol)     .is :back_slash, :eol

      a(:eol).as NewLine
      a(:escaped_eol).as EscapedNewLine

      a(:line_comment)    .is "#", ["#", "!", " "], a(:eol).but.any

      a(:tab).as(Tab/8)   .is "\t"
      a(:whitespace)      .is " "
      a(:space).as(Space) .is a([:whitespace, :tab, :escaped_eol]).many

      a(:alpha)           .is /[a-zA-Z]/
      a(:bin_digit)       .is /[01]/
      a(:oct_digit)       .is /[0-7]/
      a(:hex_digit)       .is /[0-9a-fA-F]/
      a(:dec_digit)       .is /[0-9]/

      a(:digits).is do |digit|
        a(digit, a([ digit, a(:underscore, digit) ]).any)
      end

      a(:bin_int).as(NumberLiteral/2)  .is "0", /[bB]/, a(:digits).of(:oct_digit)
      a(:oct_int).as(NumberLiteral/8)  .is "0", a(/[oO]/).opt, a(:digits).of(:oct_digit)
      a(:dec_int).as(NumberLiteral/10) .is a(:digits).of(:dec_digit)
      a(:hex_int).as(NumberLiteral/16) .is "0", /[xX]/, a(:digits).of(:hex_digit)

      a(:integer).is [:bin_int, :hex_int, :oct_int, :dec_int]

      text = lambda do |left, right|
        interpol = a(:dollar, :table)
        escaped = a(:back_slash, [:dollar, right])
        char = a(right.not, :any)
        content = interpol | (escaped | char).many
        a(left, content.any, right)
      end

      a(:string).as(StringLiteral).is text.call(a("\""), a("\""))
      a(:mstring).as(StringLiteral).tap do |ms|
        mq = a("\"", "\"", "\"")
        ms.is text.call(mq, mq)
      end

    end
  end
end
