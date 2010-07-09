use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer parseText for symbol literals", 

  parse = fn(txt, Akin Tokenizer parseText(txt))

  it("should parse simple symbol",
    msg = parse(":hello")
    msg name should be nil
    msg should not have body
    msg should be literal
    msg literal type should == :symbolIdentifier
    msg literal text should == "hello"
  )

  it("should parse simple symbol from string",
    msg = parse(":\"hello\"")
    msg name should be nil
    msg should not have body
    msg should be literal
    msg literal type should == :symbolText
    msg literal parts first should == "hello"
  )


)
