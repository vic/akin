require 'rspec/core/rake_task'
require 'rbconfig'

RSpec::Core::RakeTask.new(:spec)

def _(path)
  File.expand_path('../'+path, __FILE__)
end

file _('lib/akin/grammar.rb') => file(_('lib/akin/grammar.kpeg')) do |t|
  cmd = []
  if File.file? _('../kpeg/bin/kpeg')
    cmd << Config::CONFIG['ruby_install_name']
    cmd << '-I' << _('../kpeg/lib')
    cmd << _('../kpeg/bin/kpeg')
  else
    cmd << 'kpeg'
  end
  cmd << '--stand-alone' << '--force'
  cmd << '--output' << t.name
  cmd << t.prerequisites.first.to_s
  sh *cmd
end

task :grammar => _('lib/akin/grammar.rb')

task :default => [:grammar, :spec ]
