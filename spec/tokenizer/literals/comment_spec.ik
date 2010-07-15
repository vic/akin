use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer parseText for comments", 

  parse = fn(txt, Akin Tokenizer parseText(txt))

  it("should treat documentation starting with /* as documentation ",
    msg = parse("/* This is a comment */")
    msg should be document
    msg text should == "/* This is a comment */"
    msg type should == :document
  )

  it("should parse a # followed by space as a whole line comment",
    msg = parse("# hey")
    msg should be comment
    msg type should == :comment
    msg text should == "# hey"
  )

  it("should parse a # followed by # as a whole line comment",
    msg = parse("##hey")
    msg should be comment
    msg type should == :comment
    msg text should == "##hey"
  )

  it("should treat comments as whitespace, starting from #! to end of line",
    msg = parse("  #! A comment in akin\n is upto #! the end of line")
    msg should be space
    msg succ should be comment
    msg succ type should == :comment
    msg succ text should == "#! A comment in akin"
    msg succ succ should be terminator
    msg succ succ succ should be space
    msg succ succ succ succ text should == "is"
    msg succ succ succ succ succ should be space
    msg succ succ succ succ succ succ text should == "upto"
    msg succ succ succ succ succ succ succ should be space
    msg succ succ succ succ succ succ succ succ should be comment
    msg succ succ succ succ succ succ succ succ type should == :comment
    msg succ succ succ succ succ succ succ succ text should == "#! the end of line"
  )


)
