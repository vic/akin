module Akin
  # Command Line Interface to Akin.
  class CLI
    def initialize
      @print = Compiler::Print.new
      @compile_only = false
      @evals = []
      @rest = []
    end

    def main(argv=ARGV)
      options(argv)
      return repl if @rest.empty? && @evals.empty? && !@compile_only
      evals unless @evals.empty?
      script unless @rest.empty?
      compile if @compile_only
    end

    # Batch compile all files given as arguments.
    def compile
      @rest.each do |f|
        begin
          Compiler.compile_file f, nil, @print
        rescue Compiler::Error => e
          e.show
        end
      end
    end

    # Evaluate code given on command line
    def evals
      bnd = Object.new
      def bnd.get; binding; end
      bnd = bnd.get
      mod = raise "Not implemented"
      @evals.each do |code|
        CodeLoader.execute_code code, bnd, mod, @print
      end
    end

    # Run the given script if any
    def script
      puts "hello world"
      return
      CodeLoader.execute_file @rest.first, nil, @print
    end

    # Run the Akin REPL unless we were given an script
    def repl
      require 'akin/repl'
      REPL.new(@print).main
    end

    # Parse command line options
    def options(argv)
      options = Rubinius::Options.new "Usage: akin [options] [program]", 20
      options.doc ""
      options.doc "OPTIONS:"

      options.on "-", "Read and evalute code from STDIN" do
        @evals << STDIN.read
      end

      options.on "--print-ast", "Print the Akin AST" do
        @print.ast = true
      end

      options.on "--print-asm", "Print the Rubinius ASM" do
        @print.asm = true
      end

      options.on "--print-sexp", "Print the Akin Sexp" do
        @print.sexp = true
      end

      options.on "--print-all", "Print Sexp, AST and Rubinius ASM" do
        @print.ast = @print.asm = @print.sexp = true
      end

      options.on "-C", "--compile", "Just batch compile dont execute." do
        @compile_only = true
      end

      options.on "-e", "CODE", "Execute CODE" do |e|
        @evals << e
      end

      options.on "--version", "Print version and exit" do
	require 'akin/version'
        puts Version.full_string
        exit 0
      end

      options.on "-h", "--help", "Display this help" do
        puts options
        exit 0
      end

      options.doc ""

      @rest = options.parse(argv)
    end

  end
end
