require 'ostruct'
require 'optparse'

module Akin
  module Command

    COMPILE_TARGETS = %w[rbx sexp]

    extend self
    
    def run(argv)
      opts = options(argv)
    end

    def options(argv)
      opts = OpenStruct.new
      parser = OptionParser.new do |parser|
        parser.separator ""
        parser.separator "OPTIONS"

        parser.on("-c", "--compile [TARGET]", COMPILE_TARGETS,
               "Just compile sources.",
               "TARGET can be one of: #{COMPILE_TARGETS.join(', ')}",
               "Default: #{COMPILE_TARGETS.first}") do |target|
          opts.target = target || COMPILE_TARGETS.first
        end

        parser.on("-h", "--help") do
          puts parser
          exit 0
        end
      end
      opts.argv = parser.parse(argv)
      opts
    end
    
  end
end
