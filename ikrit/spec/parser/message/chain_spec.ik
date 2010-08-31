use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser parseText", 

  parse = fn(txt, Akin Parser parseText(txt))

  it("should set fwd message",
    msg = parse("foo(bar, baz) bat")

    msg should not be nil
    msg text should == "foo"

    msg at(1) should be space
    msg at(2) text should == "bat"

    msg arg(0) text should == "bar"
    msg arg(1) text should == "baz"

    msg text should == "foo"
    msg body should not be nil
    msg body message text should == "bar"
    msg body message fwd should be enumerator
    msg body message fwd fwd should be space
    msg body message fwd fwd fwd text should == "baz"
    msg body message fwd fwd fwd fwd should be nil
    msg fwd should be space
    msg fwd fwd text should == "bat"
  )

  it("should parse message enumeration", 
    msg = parse("a,b,c") 

    msg[0] should == msg
    msg[0] text should == "a"

    msg text should == "a"
    msg fwd text should == ","
    msg fwd fwd text should == "b"
    msg fwd fwd fwd text should == ","
    msg fwd fwd fwd fwd text should == "c"
  )


  it("should parse message enumeration with spaces", 
    msg = parse("a , b, c  ")
    msg text should == "a"
    msg at(1) should be space
    msg at(2) should be enumerator
    msg at(3) should be space
    msg at(4) text should == "b"
    msg at(5) should be enumerator
    msg at(6) should be space
    msg at(7) text should == "c"
    msg at(8) should be space
    msg at(9) should be nil
  )

  it("should parse message enumeration with new lines", 
    msg = parse("a ,\n b,\t\n c  ")
    msg text should == "a"
    msg at(1) should be space
    msg at(2) should be enumerator
    msg at(3) should be terminator
    msg at(4) should be space
    msg at(5) text should == "b"
    msg at(6) should be enumerator
    msg at(7) should be space
    msg at(8) should be terminator
    msg at(9) should be space
    msg at(10) text should == "c"
    msg at(11) should be space
    msg at(11) fwd should be nil
  )

  it("should parse message enumeration with new lines and linecomment", 
    msg = parse("a ,\n b,#! a comment here\n c  ")
    msg text should == "a"
    msg at(1) should be space
    msg at(2) should be enumerator
    msg at(3) should be terminator
    msg at(4) should be space
    msg at(5) text should == "b"
    msg at(6) should be enumerator
    msg at(7) should be comment
    msg at(8) should be terminator
    msg at(9) should be space
    msg at(10) text should == "c"
    msg at(11) should be space
    msg at(12) should be nil
  )

  it("should correctly parse chained invocations",
    msg = parse("hello(world) {good} [bye]") 
    msg text should == "hello"
    msg should be call
    msg body should be round
    msg body message text should == "world"
    msg fwd text should == " "
    msg fwd fwd body should be curly
    msg fwd fwd fwd text should == " "
    msg fwd fwd fwd fwd body should be square
  )

  it("should correctly parse chained invocations without inner spaces",
    msg = parse("hello(world){good}[bye]") 
    msg text should == "hello"
    msg should be call
    msg body should be round
    msg body message text should == "world"
    msg fwd text should be nil
    msg fwd body should be curly
    msg fwd body message text should == "good"
    msg fwd fwd text should be nil
    msg fwd fwd body should be square
    msg fwd fwd body message text should == "bye"
  )

  it("should have indentation level per line",
    
    msg = parse("
    # akin python indentation
      if foo
        yes
    # line comments are inexpression
      else
        no
      outsider 
    ")
    
    msg expression(0) text should == "if"
    msg expression(0) lineIndentLevel should == 6
    msg expression(1) text should == "foo"
    msg expression(1) lineIndentLevel should == 6
    msg expression(2) text should == "yes"
    msg expression(2) lineIndentLevel should == 8
    msg expression(3) text should == "else"
    msg expression(3) lineIndentLevel should == 6
    msg expression(4) text should == "no"
    msg expression(4) lineIndentLevel should == 8
    msg expression(5) text should == "outsider"
    msg expression(5) lineIndentLevel should == 6
  )

  
  
)