use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer parseText", 

  parse = fn(txt, Akin Tokenizer parseText(txt))


  it("should parse as two messages if : has spaces",
    msg = parse("hello : world")
    msg should not be nil
    msg name should == :hello
    msg succ should be space
    msg succ succ name should == :(":")
    msg succ succ succ should be space
    msg succ succ succ succ name should == :world
    
    msg expression(0) name should == :hello
    msg expression(1) name should == :(":")
    msg expression(2) name should == :world
  )

  it("should parse =",
    msg = parse("hello= world")
    msg expression(0) name should == :hello
    msg expression(1) name should == :("=")
    msg expression(2) name should == :world
  )

  it("should parse as two messages if = has spaces",
    msg = parse("hello = world")
    msg expression(0) name should == :hello
    msg expression(1) name should == :("=")
    msg expression(2) name should == :world
  )

  it("should parse operators starting with #",
    msg = parse("#$!")
    msg name should == :("#$!")
  )
  
)
