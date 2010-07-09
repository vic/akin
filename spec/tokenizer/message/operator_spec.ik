use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer parseText", 

  parse = fn(txt, Akin Tokenizer parseText(txt))


  it("should parse as two messages if : has spaces",
    msg = parse("hello : world")
    msg should not be nil
    msg name should == :hello
    msg next should be space
    msg next next name should == :(":")
    msg next next next should be space
    msg next next next next name should == :world
    
    msg visible(0) name should == :hello
    msg visible(1) name should == :(":")
    msg visible(2) name should == :world
  )

  it("should parse =",
    msg = parse("hello= world")
    msg visible(0) name should == :hello
    msg visible(1) name should == :("=")
    msg visible(2) name should == :world
  )

  it("should parse as two messages if = has spaces",
    msg = parse("hello = world")
    msg visible(0) name should == :hello
    msg visible(1) name should == :("=")
    msg visible(2) name should == :world
  )
  
)
