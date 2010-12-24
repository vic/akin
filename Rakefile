require 'rake/gempackagetask'

task :default => :spec

desc "Run the specs (default)"
task :spec => :build do
  sh "mspec spec"
end

desc "Clean generated files"
task :clean do
  rm_f FileList["**/*.rbc"]
  rm_rf FileList["pkg"]
end

task :build

spec = Gem::Specification.new do |s|
  require File.expand_path('../lib/akin/version', __FILE__)

  s.name                      = 'akin'
  s.version                   = Akin::Version.to_s

  s.specification_version     = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors                   = ["Victor Hugo Borja"]
  s.date                      = %q{2010-12-23}
  s.email                     = %q{vic.borja@gmail.com}
  s.has_rdoc                  = true
  s.extra_rdoc_files          = FileList[ '**/*/README.md' ]
  s.executables               = ["akin"]
  s.files                     = FileList[ '{bin,lib,spec}/**/*.{yaml,txt,rb}', 'Rakefile', *s.extra_rdoc_files ]
  s.homepage                  = %q{http://github.com/vic/akin}
  s.require_paths             = ["lib"]
  s.rubygems_version          = %q{1.3.5}
  s.summary                   = "An Akin programming language optimized for fun."
  s.description               = <<EOS
An Akin programming language optimized for fun.
EOS

  s.rdoc_options << '--title' << 'Akin' <<
                    '--main' << 'README.md' <<
                    '--line-numbers'
  s.add_dependency 'mspec', '~> 1.5.0'
end

Rake::GemPackageTask.new(spec){ |pkg| pkg.gem_spec = spec }
