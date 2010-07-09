use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer parseText for comments", 

  parse = fn(txt, Akin Tokenizer parseText(txt))

  it("should treat documentation starting with /* as documentation ",
    msg = parse("/* This is a comment */")
    msg name should be nil
    msg should be literal
    msg literal text should == "/* This is a comment */"
    msg literal type should == :document
  )

  it("should parse a # followed by space as a whole line comment",
    msg = parse("# hey")
    msg should be literal
    msg literal type should == :comment
    msg literal text should == "# hey"
  )

  it("should treat comments as whitespace, starting from #! to end of line",
    msg = parse("  #! A comment in akin\n is upto #! the end of line")
    msg should be space
    msg next should be literal
    msg next literal type should == :comment
    msg next literal text should == "#! A comment in akin"
    msg next next should be terminator
    msg next next next should be space
    msg next next next next name should == :is
    msg next next next next next should be space
    msg next next next next next next name should == :upto
    msg next next next next next next next should be space
    msg next next next next next next next next should be literal
    msg next next next next next next next next literal type should == :comment
    msg next next next next next next next next literal text should == "#! the end of line"
  )


)
