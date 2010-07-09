use("ispec")


use("akin")
use("akin/parser")

describe("Akin Parser", 

  parse = fn(txt, 
    tokens = Akin Tokenizer parseText(txt)
    Akin Parser Rewrite Colon rewrite(tokens))

  it("should do nothing if : takes parameters",
    msg = parse("hello :(bar) baz")
    msg visible(0) name should == :hello
    msg visible(1) name should == :(":")
    msg visible(1) arg(0) name should == :bar
    msg visible(2) name should == :baz
  )

  it("should do nothing if : starts a symbol",
    msg = parse("hello :bar baz")
    msg visible(0) name should == :hello
    msg visible(1) should be literal
    msg visible(1) literal type should == :symbolIdentifier
    msg visible(2) name should == :baz
  )


)

