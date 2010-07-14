use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer parseText sets message position", 

  parse = fn(txt, file :foo, ln 1, co 1, pos 1,
    Akin Tokenizer parseText(txt, filename: file, line: ln, col: co, pos: pos))

  it("should produce Messages with position data",
    msg = parse("hello")
    msg position logical asList should == [:foo, 1, 1, 1]
  )

  it("should track position as data is read", 
    msg = parse("  \n  \n  hello")
    msg visible name should == :hello
    msg visible position logical asList should == [:foo, 3, 3, 9]
  )

  it("should treat escaped new line as space",
    msg = parse("hello\\\nworld")
    msg name should == :hello
    msg succ name should == :("")
    msg succ succ name should == :world
    msg succ succ position physical asList should == [:foo, 2, 1, 8]
    msg succ succ position logical asList should == [:foo, 1, 7, 7]
  )

  it("should handle \\r\\n as a single terminator",
    msg = parse("hello\r\nworld")
    msg at(0) name should == :hello
    msg at(1) should be terminator
    msg at(2) name should == :world
    msg at(2) position logical asList should == [:foo, 2, 1, 7]
  )

  it("should handle \\r\\r as a two terminators",
    msg = parse("hello\r\rworld")
    msg at(0) name should == :hello
    msg at(1) should be terminator
    msg at(1) name should == :("\n")
    msg at(2) should be terminator
    msg at(2) name should == :("\n")
    msg at(3) name should == :world
    msg at(3) position logical asList should == [:foo, 3, 1, 8]
  )


)
