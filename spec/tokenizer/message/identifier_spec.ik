use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer parseText message identifiers", 

  parse = fn(txt, Akin Tokenizer parseText(txt))

  it("should parse simple identifier",
    msg = parse("hello")
    msg should not be nil
    msg should be identifier
    msg text should == "hello"
    msg should not be call
  )

  it("should parse simple identifier including $",
    msg = parse("hel$lo")
    msg should not be nil
    msg text should == "hel$lo"
    msg should not be call
  )

  it("should parse simple identifier ending in ?",
    msg = parse("hello?")
    msg should not be nil
    msg text should == "hello?"
    msg should not be call
  )

  it("should parse simple identifier ending in ?",
    msg = parse("hello?world?")
    msg should not be nil
    msg text should == "hello?world?"
    msg should not be call
  )

  it("should parse simple identifier including :",
    msg = parse("hel:lo::there")
    msg should not be nil
    msg text should == "hel:lo::there"
    msg should not be call
  )

  it("should parse identifier with : at end as two messages",
    msg = parse("hello:")
    msg should not be nil
    msg text should == "hello"
    msg should not be call
    msg succ text should == ":"
  )
  

)
