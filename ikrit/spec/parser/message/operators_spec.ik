use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser parseText for symbol literals", 

  parse = fn(txt, 
    let(Akin Parser Rewrite rewriters, list,
      Akin Parser parseText(txt)
    )
  )

  it("should parse single : as an operator",
    msg = parse(":")
    msg type should == :operator
    msg text should == ":"
    msg fwd should be nil
  )

  it("should parse two : as single operator",
    msg = parse("::")
    msg type should == :operator
    msg text should == "::"
    msg fwd should be nil
  )

  it("should parse three : as single operator",
    msg = parse(":::")
    msg type should == :operator
    msg text should == ":::"
    msg fwd should be nil
  )

  it("should parse four : as single operator",
    msg = parse("::::")
    msg type should == :operator
    msg text should == "::::"
    msg fwd should be nil
  )

  it("should parse one . as punctuation",
    msg = parse(".")
    msg type should == :punctuation
    msg text should == "."
    msg fwd should be nil
  )

  it("should parse two . as operator",
    msg = parse("..")
    msg type should == :operator
    msg text should == ".."
    msg fwd should be nil
  )

  it("should parse three . as operator",
    msg = parse("...")
    msg type should == :operator
    msg text should == "..."
    msg fwd should be nil
  )

  it("should parse :. as two operators",
    msg = parse(":.")
    msg type should == :operator
    msg text should == ":"
    msg fwd should be terminator
  )

  it("should allow inner : in operators",
    msg = parse("<:>")
    msg type should == :operator
    msg text should == "<:>"
    msg fwd should be nil
  )

  it("should parse ending : as another operator",
    msg = parse("=:")
    msg type should == :operator
    msg text should == "="
    msg fwd should be operator
    msg fwd text should == ":"
  )

  it("should not parse ending : as another operator when braces are present",
    msg = parse("=:()")
    msg type should == :operator
    msg text should == "=:"
    msg fwd should be nil
  )

  it("should not parse ending : as another operator when braces are present",
    msg = parse("::()")
    msg type should == :operator
    msg text should == "::"
    msg fwd should be nil
  )

  it("should parse ending double : as single operator",
    msg = parse("=::")
    msg type should == :operator
    msg text should == "=::"
    msg fwd should be nil
  )

  it("should parse operators starting with : as single operator",
    msg = parse(":=")
    msg type should == :operator
    msg text should == ":="
    msg fwd should be nil
  )

  it("should parse operators starting with many : as single operator",
    msg = parse(":::=")
    msg type should == :operator
    msg text should == ":::="
    msg fwd should be nil
  )

  it("should each ; as single punctuation",
    msg = parse(";;;")
    msg type should == :punctuation
    msg text should == ";"
    msg fwd type should == :punctuation
    msg fwd fwd type should == :punctuation
  )

)
