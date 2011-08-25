%w{

 parser
 grammar
 operator
 shuffle

}.each { |f| require File.expand_path("../akin/#{f}", __FILE__) }

