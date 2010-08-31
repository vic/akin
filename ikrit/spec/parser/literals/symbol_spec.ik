use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser parseText for symbol literals", 

  parse = fn(txt, Akin Parser parseText(txt))

  it("should parse simple symbol",
    msg = parse(":hello")
    msg should not be call
    msg type should == :symbolIdentifier
    msg text should == "hello"
  )

  it("should parse simple symbol from string",
    msg = parse(":\"hello\"")
    msg should not be call
    msg type should == :symbolText
    msg literal[:parts] first should == "hello"
  )


)