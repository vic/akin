use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser parseText sets message position", 

  parse = fn(txt, file "foo", ln 1, co 1, pos 1,
    Akin Parser parseText(txt, filename: file, line: ln, col: co, pos: pos))

  it("should produce Messages with position data",
    msg = parse("hello")
    msg position logical asList should == ["foo", 1, 1, 1]
  )

  it("should track position as data is read", 
    msg = parse("  \n  \n  hello")
    msg expression text should == "hello"
    msg expression position logical asList should == ["foo", 3, 3, 9]
  )

  it("should treat escaped new line as space",
    msg = parse("hello\\\nworld")
    msg text should == "hello"
    msg fwd text should == " "
    msg fwd fwd text should == "world"
    msg fwd fwd position physical asList should == ["foo", 2, 1, 8]
    msg fwd fwd position logical asList should == ["foo", 1, 7, 7]
  )

  it("should handle \\r\\n as a single terminator",
    msg = parse("hello\r\nworld")
    msg at(0) text should == "hello"
    msg at(1) should be terminator
    msg at(2) text should == "world"
    msg at(2) position logical asList should == ["foo", 2, 1, 7]
  )

  it("should handle \\r\\r as a two terminators",
    msg = parse("hello\r\rworld")
    msg at(0) text should == "hello"
    msg at(1) should be terminator
    msg at(1) text should == "\n"
    msg at(2) should be terminator
    msg at(2) text should == "\n"
    msg at(3) text should == "world"
    msg at(3) position logical asList should == ["foo", 3, 1, 8]
  )


)
