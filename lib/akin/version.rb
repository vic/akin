require 'rbconfig'

module Akin

  module Version
    extend self

    attr_accessor :major, :minor, :tiny, :commit, :codename, :tagline

    self.codename = "Pinole"
    self.tagline = "Optimized for fun"

    self.major = 0
    self.minor = 0
    self.tiny = 1

    def commit
      @commit ||= `git rev-parse HEAD`[0..7]
    end

    def to_s
      [major, minor, tiny].join(".")
    end

    def to_str
      to_s
    end

    def full_string(sep = "\n")
      [akin_string, rbx_string].join(sep)
    end

    def akin_string
      "Akin #{to_s} (#{commit}) \"#{codename}\""
    end

    # Returns a partial Ruby version string based on +which+. For example,
    # if RUBY_VERSION = 8.2.3 and RUBY_PATCHLEVEL = 71:
    #
    #  :major  => "8"
    #  :minor  => "8.2"
    #  :tiny   => "8.2.3"
    #  :teeny  => "8.2.3"
    #  :full   => "8.2.3.71"
    def self.ruby_version(which = :minor)
      case which
      when :major
        n = 1
      when :minor
        n = 2
      when :tiny, :teeny
        n = 3
      else
        n = 4
      end

      patch = RUBY_PATCHLEVEL.to_i
      patch = 0 if patch < 0
      version = "#{RUBY_VERSION}.#{patch}"
      version.split('.')[0,n].join('.')
    end

    def rbx_string
      "Rubinius #{Rubinius::VERSION} ("+
        "#{Rubinius::BUILD_REV[0..7]} "+
        "Ruby #{ruby_version(:tiny)} "+
        "#{Rubinius::RELEASE_DATE})"
    end
  end
end

