use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser parseText", 

  parse = fn(txt, Akin Parser parseText(txt))

  it("should parse simple identifier",
    msg = parse("hello")
    msg should not be nil
    msg name should == :hello
    msg should not be activation
  )

  it("should parse simple message",
    msg = parse("hello()") 
    msg name should == :hello
    msg should be activation
    msg activation body should be nil
  )

  it("should set next message",
    msg = parse("foo(bar, baz) bat") 
    msg should not be nil
    msg name should == :foo
    msg should be activation
    msg activation body name should == :bar
    msg activation body next name should == :(",")
    msg activation body next next name should == :baz
    msg activation body next next next should be nil
    msg next name should == :bat
    msg next should not be activation
  )

  it("should parse message list", 
    msg = parse("a,b,c") 
    msg name should == :a
    msg next name should == :(",")
    msg next next name should == :b
    msg next next next name should == :(",")
    msg next next next next name should == :c
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

  it("should correctly parse chained invocations",
    msg = parse("hello(world) {good} [bye]") 
    msg name should == :hello
    msg should be activation
    msg activation should be round
    msg activation body name should == :world
    msg next name should == :""
    msg next activation should be curly
    msg next next name should == :""
    msg next next activation should be square
  )

  it("should correctly parse chained invocations without inner spaces",
    msg = parse("hello(world){good}[bye]") 
    msg name should == :hello
    msg should be activation
    msg activation should be round
    msg activation body name should == :world
    msg next name should == :""
    msg next activation should be curly
    msg next next name should == :""
    msg next next activation should be square
  )

  it("should parse hexadecimal literal",
    msg = parse("0xCAFEBABE")
    msg name should be nil
    msg should not be activation
    msg should be literal
    msg literal type should == :hexNumber
    msg literal text should == "CAFEBABE"
  )

  it("should parse decimal integer literal",
    msg = parse("24") 
    msg name should be nil
    msg should not be activation
    msg should be literal
    msg literal type should == :decNumber
    msg literal integerText = "24"
  )

)
