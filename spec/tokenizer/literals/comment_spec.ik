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

  it("should parse a # followed by # as a whole line comment",
    msg = parse("##hey")
    msg should be literal
    msg literal type should == :comment
    msg literal text should == "##hey"
  )

  it("should treat comments as whitespace, starting from #! to end of line",
    msg = parse("  #! A comment in akin\n is upto #! the end of line")
    msg should be space
    msg succ should be literal
    msg succ literal type should == :comment
    msg succ literal text should == "#! A comment in akin"
    msg succ succ should be terminator
    msg succ succ succ should be space
    msg succ succ succ succ name should == :is
    msg succ succ succ succ succ should be space
    msg succ succ succ succ succ succ name should == :upto
    msg succ succ succ succ succ succ succ should be space
    msg succ succ succ succ succ succ succ succ should be literal
    msg succ succ succ succ succ succ succ succ literal type should == :comment
    msg succ succ succ succ succ succ succ succ literal text should == "#! the end of line"
  )


)
