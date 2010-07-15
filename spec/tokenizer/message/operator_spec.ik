use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer parseText", 

  parse = fn(txt, Akin Tokenizer parseText(txt))


  it("should parse as two messages if : has spaces",
    msg = parse("hello : world")
    msg should not be nil
    msg text should == "hello"
    msg succ should be space
    msg succ succ text should == ":"
    msg succ succ succ should be space
    msg succ succ succ succ text should == "world"
    
    msg expression(0) text should == "hello"
    msg expression(1) text should == ":"
    msg expression(2) text should == "world"
  )

  it("should parse =",
    msg = parse("hello= world")
    msg expression(0) text should == "hello"
    msg expression(1) text should == "="
    msg expression(2) text should == "world"
  )

  it("should parse as two messages if = has spaces",
    msg = parse("hello = world")
    msg expression(0) text should == "hello"
    msg expression(1) text should == "="
    msg expression(2) text should == "world"
  )

  it("should parse operators starting with #",
    msg = parse("#$!")
    msg text should == "#$!"
  )
  
)
