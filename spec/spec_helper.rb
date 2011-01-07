File.expand_path("../../lib", __FILE__).tap do |lib|
  $LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib
end

require 'akin/parser/position'
require 'akin/parser/char_reader'
require 'akin/parser/match'
require 'akin/parser/language'
require 'akin/parser/syntax'
