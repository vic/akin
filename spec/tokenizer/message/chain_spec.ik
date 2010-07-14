use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer parseText", 

  parse = fn(txt, Akin Tokenizer parseText(txt))

  it("should set succ message",
    msg = parse("foo(bar, baz) bat")

    msg should not be nil
    msg name should == :foo

    msg at(1) should be space
    msg at(2) name should == :bat

    msg arg(0) name should == :bar
    msg arg(1) name should == :baz

    msg name should == :foo
    msg body should not be nil
    msg body message name should == :bar
    msg body message succ should be enumerator
    msg body message succ succ should be space
    msg body message succ succ succ name should == :baz
    msg body message succ succ succ succ should be nil
    msg succ should be space
    msg succ succ name should == :bat
  )

  it("should parse message enumeration", 
    msg = parse("a,b,c") 

    msg[0] should == msg
    msg[0] name should == :a

    msg name should == :a
    msg succ name should == :(",")
    msg succ succ name should == :b
    msg succ succ succ name should == :(",")
    msg succ succ succ succ name should == :c
  )


  it("should parse message enumeration with spaces", 
    msg = parse("a , b, c  ")
    msg name should == :a
    msg at(1) should be space
    msg at(2) should be enumerator
    msg at(3) should be space
    msg at(4) name should == :b
    msg at(5) should be enumerator
    msg at(6) should be space
    msg at(7) name should == :c
    msg at(8) should be space
    msg at(9) should be nil
  )

  it("should parse message enumeration with new lines", 
    msg = parse("a ,\n b,\t\n c  ")
    msg name should == :a
    msg at(1) should be space
    msg at(2) should be enumerator
    msg at(3) should be terminator
    msg at(4) should be space
    msg at(5) name should == :b
    msg at(6) should be enumerator
    msg at(7) should be space
    msg at(8) should be terminator
    msg at(9) should be space
    msg at(10) name should == :c
    msg at(11) should be space
    msg at(11) succ should be nil
  )

  it("should parse message enumeration with new lines and linecomment", 
    msg = parse("a ,\n b,#! a comment here\n c  ")
    msg name should == :a
    msg at(1) should be space
    msg at(2) should be enumerator
    msg at(3) should be terminator
    msg at(4) should be space
    msg at(5) name should == :b
    msg at(6) should be enumerator
    msg at(7) should be comment
    msg at(8) should be terminator
    msg at(9) should be space
    msg at(10) name should == :c
    msg at(11) should be space
    msg at(12) should be nil
  )

  it("should correctly parse chained invocations",
    msg = parse("hello(world) {good} [bye]") 
    msg name should == :hello
    msg should have body
    msg body should be round
    msg body message name should == :world
    msg succ name should == :""
    msg succ body should be curly
    msg succ succ name should == :""
    msg succ succ body should be square
  )

  it("should correctly parse chained invocations without inner spaces",
    msg = parse("hello(world){good}[bye]") 
    msg name should == :hello
    msg should have body
    msg body should be round
    msg body message name should == :world
    msg succ name should be nil
    msg succ body should be curly
    msg succ body message name should == :good
    msg succ succ name should be nil
    msg succ succ body should be square
    msg succ succ body message name should == :bye
  )

  it("should have indentation level per line",
    
    msg = parse("
    #! akin python indentation
      if foo
        yes
    #! line comments are inexpression
      else
        no
      outsider 
    ")
    
    msg expression(0) name should == :if
    msg expression(0) lineIndentLevel should == 6
    msg expression(1) name should == :foo
    msg expression(1) lineIndentLevel should == 6
    msg expression(2) name should == :yes
    msg expression(2) lineIndentLevel should == 8
    msg expression(3) name should == :else
    msg expression(3) lineIndentLevel should == 6
    msg expression(4) name should == :no
    msg expression(4) lineIndentLevel should == 8
    msg expression(5) name should == :outsider
    msg expression(5) lineIndentLevel should == 6
  )

  
  
)
