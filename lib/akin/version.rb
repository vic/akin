module Akin
  module VERSION
    extend self
    attr_accessor :codename, :major, :minor, :patch

    self.codename = "Kevin"
    self.major = 0
    self.minor = 0
    self.patch = 0

    def commit
      `git rev-parse HEAD`[0..4]
    end

    def full_version
      [major, minor, patch, commit].join(".")
    end

    def to_s
      [major, minor, patch].join(".")
    end
  end
end
