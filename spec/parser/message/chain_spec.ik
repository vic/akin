use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser parseText", 

  parse = fn(txt, Akin Parser parseText(txt))

  it("should set next message",
    msg = parse("foo(bar, baz) bat") 
    msg should not be nil
    msg name should == :foo
    msg should be activation
    msg activation body name should == :bar
    msg activation body next name should == :(",")
    msg activation body next next name should == :baz
    msg activation body next next next should be nil
    msg next name should == :bat
    msg next should not be activation
  )

  it("should parse message enumeration", 
    msg = parse("a,b,c") 
    msg name should == :a
    msg next name should == :(",")
    msg next next name should == :b
    msg next next next name should == :(",")
    msg next next next next name should == :c
  )

  it("should parse message enumeration with spaces", 
    msg = parse("a , b, c  ")
    msg name should == :a
    msg next name should == :(",")
    msg next next name should == :b
    msg next next next name should == :(",")
    msg next next next next name should == :c
    msg next next next next next should be nil
  )

  it("should correctly parse chained invocations",
    msg = parse("hello(world) {good} [bye]") 
    msg name should == :hello
    msg should be activation
    msg activation should be round
    msg activation body name should == :world
    msg next name should == :""
    msg next activation should be curly
    msg next next name should == :""
    msg next next activation should be square
  )

  it("should correctly parse chained invocations without inner spaces",
    msg = parse("hello(world){good}[bye]") 
    msg name should == :hello
    msg should be activation
    msg activation should be round
    msg activation body name should == :world
    msg next name should == :""
    msg next activation should be curly
    msg next next name should == :""
    msg next next activation should be square
  )

  it("should parse as two messages is : has spaces",
    msg = parse("hello : world")
    msg should not be nil
    msg name should == :hello
    msg next name should == :(":")
    msg next next name should == :world
  )
  
)
