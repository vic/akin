use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser parseText on message activations", 

  parse = fn(txt, Akin Parser parseText(txt))

  it("should parse simple activation",
    msg = parse("hello()") 
    msg name should == :hello
    msg should be activation
    msg activation body should be nil
  )

  it("should parse round-bracketed empty message",
    msg = parse("(hello)") 
    msg name should == :("")
    msg should be activation
    msg activation should be round
    msg activation body name should == :hello
  )

  it("should parse square-bracketed empty message",
    msg = parse("[hello]") 
    msg name should == :("")
    msg should be activation
    msg activation should be square
    msg activation body name should == :hello
  )

  it("should parse curly-bracketed empty message",
    msg = parse("{hello}") 
    msg name should == :("")
    msg should be activation
    msg activation should be curly
    msg activation body name should == :hello
  )

  it("should parse chevron-bracketed empty message",
    msg = parse("⟨hello⟩")
    msg name should == :("")
    msg should be activation
    msg activation should be chevron
    msg activation body name should == :hello
  )

)
