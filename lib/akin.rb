%w{

 parser
 grammar
 shuffle

}.each { |f| require File.expand_path("../akin/#{f}", __FILE__) }

