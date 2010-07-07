use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser parseText", 

  parse = fn(txt, Akin Parser parseText(txt))

  it("should parse as two messages if : has spaces",
    msg = parse("hello : world")
    msg should not be nil
    msg name should == :hello
    msg next name should == :(":")
    msg next next name should == :world
  )

  it("should parse as two messages if = has spaces",
    msg = parse("hello= = world")
    msg should not be nil
    msg name should == :"hello="
    msg next name should == :("=")
    msg next next name should == :world
  )

  it("should parse as two messages if = has spaces",
    msg = parse("hello = world")
    msg should not be nil
    msg name should == :hello
    msg next name should == :("=")
    msg next next name should == :world
  )
  
)
