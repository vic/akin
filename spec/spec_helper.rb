File.expand_path("../../lib", __FILE__).tap do |lib|
  $LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib
end
