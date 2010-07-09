use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer parseText on message bodys", 

  parse = fn(txt, Akin Tokenizer parseText(txt))

  it("should parse message without body",
    msg = parse("hello") 
    msg name should == :hello
    msg body should be nil
  )


  it("should parse simple body",
    msg = parse("hello()") 
    msg name should == :hello
    msg body should not be nil
    msg body message should be nil
  )

  it("should parse round-bracketed empty message",
    msg = parse("(hello)") 
    msg name should be nil
    msg body message name should == :hello
    msg body should be round
  )

  it("should parse square-bracketed empty message",
    msg = parse("[hello]") 
    msg name should be nil
    msg body message name should == :hello
    msg body should be square
  )

  it("should parse curly-bracketed empty message",
    msg = parse("{hello}") 
    msg name should be nil
    msg body message name should == :hello
    msg body should be curly
  )

  it("should parse chevron-bracketed empty message",
    msg = parse("⟨hello⟩")
    msg name should be nil
    msg body message name should == :hello
    msg body should be chevron
  )

)
