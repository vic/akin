use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer Message", 

  parse = fn(txt, Akin Tokenizer parseText(txt))

  it("should obtain fwdessive message by calling fwd",
    msg = parse("foo bat")
    msg text should == "foo"
    msg fwd should be space
    msg fwd fwd text should == "bat"
  )
  
  it("should obtain bwdiding message by calling bwd",
    msg = parse("foo bat")
    msg text should == "foo"
    msg fwd should be space
    msg fwd fwd text should == "bat"
    msg fwd fwd bwd should be space
    msg fwd fwd bwd should be(msg fwd)
    msg fwd bwd should be(msg)
  )
  
  it("should obtain next non-blank message by calling next", 
    msg = parse("foo bat")
    msg text should == "foo"
    msg next text should == "bat"
  )

  it("next should obtain next message in chain until terminator",
    msg = parse("foo bat. baz")
    msg text should == "foo"
    msg next text should == "bat"
    msg next succ should be terminator
    msg next fwd  should be terminator
    msg next next should be nil
  )

  it("next should obtain next message in chain until enumerator",
    msg = parse("foo bat, baz")
    msg text should == "foo"
    msg next text should == "bat"
    msg next succ should be comma
    msg next fwd  should be comma
    msg next next should be nil
  )

  it("next should obtain next message in chain until semicolon",
    msg = parse("foo bat; baz")
    msg text should == "foo"
    msg next text should == "bat"
    msg next succ should be semicolon
    msg next fwd  should be semicolon
    msg next next should be nil
  )

  it("next should obtain next message in chain until eol",
    msg = parse("foo bat\n baz")
    msg text should == "foo"
    msg next text should == "bat"
    msg next succ should be eol
    msg next fwd  should be eol
    msg next next should be nil
  )


  it("should obtain previous non-blank message by calling prev", 
    msg = parse("foo bat")
    msg next prev should be(msg)
  )

  it("prev should obtain prev message in chain until terminator",
    msg = parse("bat. baz foo") last
    msg text should == "foo"
    msg prev text should == "baz"
    msg prev prec should be terminator
    msg prev bwd  should be space
    msg prev prev should be nil
  )

  it("prev should obtain prev message in chain until comma",
    msg = parse("bat, baz foo") last
    msg text should == "foo"
    msg prev text should == "baz"
    msg prev prec should be comma
    msg prev bwd  should be space
    msg prev prev should be nil
  )

  it("prev should obtain prev message in chain until semicolon",
    msg = parse("bat; baz foo") last
    msg text should == "foo"
    msg prev text should == "baz"
    msg prev prec should be semicolon
    msg prev bwd  should be space
    msg prev prev should be nil
  )

  it("prev should obtain prev message in chain until eol",
    msg = parse("bat\n baz foo") last
    msg text should == "foo"
    msg prev text should == "baz"
    msg prev prec should be eol
    msg prev bwd  should be space
    msg prev prev should be nil
  )
  
  it("next= should not alter spaces between",
    msg = parse("foo bar")
    qux = parse("qux")
    bar = msg next
    msg next = qux
    msg fwd should be space
    msg fwd fwd should be(qux)
    msg next should be(qux)
    qux prev should be(msg)
    qux bwd should be space
    qux bwd should == msg fwd
    bar prev should be nil
    bar bwd should be nil
  )

  it("next= should not alter leading spaces",
    msg = parse("foo   ")
    qux = parse("qux")
    msg next should be nil
    msg fwd should be space
    msg next = qux
    msg fwd should be space
    msg fwd fwd should be(qux)
  )

  it("next= should set until terminator",
    foo = parse("foo bar. baz bat")
    msg = parse("hola adios")
    foo next text should == "bar"
    foo next = msg
    foo code should == "foo hola adios. baz bat"
  )


  it("next= should set until terminator",
    foo = parse("foo bar . baz bat")
    msg = parse("hola adios")
    foo next text should == "bar"
    foo next = msg
    foo code should == "foo hola adios . baz bat"
  )

  it("prev= should not alter spaces between",
    foo = parse("foo bar")
    qux = parse("qux")
    bar = foo next
    bar prev = qux
    bar bwd should be space
    bar bwd bwd should be(qux)
    foo next should be nil
    foo fwd should be nil
    bar prev should be(qux)
  )

  it("prev= should not alter bwdeding spaces",
    space = parse("   foo")
    qux = parse("qux")
    foo = space fwd
    foo prev = qux
    foo bwd should be space
    foo bwd bwd should be(qux)
    foo prev should be(qux)
    qux fwd should be space
    qux next should be(foo)
  )

  it("prev= should set until terminator",
    foo = parse("foo bar. baz bat")
    bat = foo last
    msg = parse("hola adios")
    bat text should == "bat"
    bat prev = msg
    foo code should == "foo bar. hola adios bat"
  )


  it("arg should obtain arguments by index",
    foo = parse("foo(  bar  , baz  )")
    foo arg(0) text should == "bar"
    foo arg(1) text should == "baz"
  )

  it("arg= should replace argument at index",
    foo = parse("hello( foo,  bar man  , baz )")
    qux = parse("qux mux")
    foo arg(0) text should == "foo"
    foo arg(1) text should == "bar"
    foo arg(2) text should == "baz"
    foo arg(1) = qux
    foo code should == "hello( foo,  qux mux  , baz )"
  )

  it("arg= should replace first argument",
    foo = parse("hello( foo,  bar man  , baz )")
    qux = parse("qux mux")
    foo arg(0) text should == "foo"
    foo arg(1) text should == "bar"
    foo arg(2) text should == "baz"
    foo arg(0) = qux
    foo code should == "hello( qux mux,  bar man  , baz )"
  )

  it("arg= should replace last argument",
    foo = parse("hello( foo,  bar man  , baz )")
    qux = parse("qux mux")
    foo arg(0) text should == "foo"
    foo arg(1) text should == "bar"
    foo arg(2) text should == "baz"
    foo arg(2) = qux
    foo code should == "hello( foo,  bar man  , qux mux )"
  )

  it("asText should quine space message",
    code = "   \t   "
    msg = parse(code)
    msg code should == code
  )

  it("asText should quine punctuation",
    code = "  foo = bar, bar. baz\n bat   "
    msg = parse(code)
    msg code should == code
  )

  it("asText should quine string literal",
    code = #[  "hello $(akin) world"  ]
    msg = parse(code)
    msg code should == code
  )

  it("asText should quine comment literal",
    code = #[  foo \n # Hello \n bar  ]
    msg = parse(code)
    msg code should == code
  )

  it("asText should quine document literal",
    code = #[  foo /* hello \n bar baz */ \n bar  ]
    msg = parse(code)
    msg code should == code
  )

)
    
