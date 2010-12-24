module Akin
  class Compiler < Rubinius::Compiler

    def self.always_recompile=(flag)
      @always_recompile = flag
    end

    class Print < Struct.new(:sexp, :ast, :asm)
    end
  end
end
