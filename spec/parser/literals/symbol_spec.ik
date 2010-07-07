use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser parseText for symbol literals", 

  parse = fn(txt, Akin Parser parseText(txt))

  it("should parse simple symbol",
    msg = parse(":hello")
    msg name should be :(":hello")
    msg should not be activation
    msg should be literal
    msg literal type should == :symbolIdentifier
    msg literal text should == "hello"
  )

  it("should parse simple symbol from string",
    msg = parse(":\"hello\"")
    msg name should be :(":")
    msg should not be activation
    msg should be literal
    msg literal type should == :symbolText
    msg literal parts first should == "hello"
  )


)
