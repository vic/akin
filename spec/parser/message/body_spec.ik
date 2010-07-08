use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser parseText on message bodys", 

  parse = fn(txt, Akin Parser parseText(txt))

  it("should parse simple body",
    msg = parse("hello()") 
    msg name should == :hello
    msg should be body
    msg body message should be nil
  )

  it("should parse round-bracketed empty message",
    msg = parse("(hello)") 
    msg name should == :("")
    msg should be body
    msg body should be round
    msg body message name should == :hello
  )

  it("should parse square-bracketed empty message",
    msg = parse("[hello]") 
    msg name should == :("")
    msg should be body
    msg body should be square
    msg body message name should == :hello
  )

  it("should parse curly-bracketed empty message",
    msg = parse("{hello}") 
    msg name should == :("")
    msg should be body
    msg body should be curly
    msg body message name should == :hello
  )

  it("should parse chevron-bracketed empty message",
    msg = parse("⟨hello⟩")
    msg name should == :("")
    msg should be body
    msg body should be chevron
    msg body message name should == :hello
  )

)
