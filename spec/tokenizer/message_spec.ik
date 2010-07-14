use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer Message", 

  parse = fn(txt, Akin Tokenizer parseText(txt))

  it("should obtain successive message by calling succ",
    msg = parse("foo bat")
    msg name should == :foo
    msg succ should be space
    msg succ succ name should == :bat
  )
  
  it("should obtain preciding message by calling prec",
    msg = parse("foo bat")
    msg name should == :foo
    msg succ should be space
    msg succ succ name should == :bat
    msg succ succ prec should be space
    msg succ succ prec should be(msg succ)
    msg succ prec should be(msg)
  )
  
  it("should obtain next non-blank message by calling next", 
    msg = parse("foo bat")
    msg name should == :foo
    msg next name should == :bat
  )

  it("should obtain previous non-blank message by calling prev", 
    msg = parse("foo bat")
    msg next prev should be(msg)
  )
  
  it("next= should not alter spaces between",
    msg = parse("foo bar")
    qux = parse("qux")
    bar = msg next
    msg next = qux
    msg succ should be space
    msg succ succ should be(qux)
    msg next should be(qux)
    qux prev should be(msg)
    qux prec should be space
    qux prec should == msg succ
    bar prev should be nil
    bar prec should be nil
  )

  it("next= should not alter leading spaces",
    msg = parse("foo   ")
    qux = parse("qux")
    msg next should be nil
    msg succ should be space
    msg next = qux
    msg succ should be space
    msg succ succ should be(qux)
  )


  it("prev= should not alter spaces between",
    foo = parse("foo bar")
    qux = parse("qux")
    bar = foo next
    bar prev = qux
    bar prec should be space
    bar prec prec should be(qux)
    foo next should be nil
    foo succ should be nil
    bar prev should be(qux)
  )

  it("prev= should not alter preceding spaces",
    space = parse("   foo")
    qux = parse("qux")
    foo = space succ
    foo prev = qux
    foo prec should be space
    foo prec prec should be(qux)
    foo prev should be(qux)
    qux succ should be space
    qux next should be(foo)
  )

  it("arg should obtain arguments by index",
    foo = parse("foo(  bar  , baz  )")
    foo arg(0) name should == :bar
    foo arg(1) name should == :baz
  )

  it("arg= should replace argument at index",
    foo = parse("hello( foo,  bar man  , baz )")
    qux = parse("qux mux")
    foo arg(0) name should == :foo
    foo arg(1) name should == :bar
    foo arg(2) name should == :baz
    foo arg(1) = qux
    foo code should == "hello( foo,  qux mux  , baz )"
  )

  it("arg= should replace first argument",
    foo = parse("hello( foo,  bar man  , baz )")
    qux = parse("qux mux")
    foo arg(0) name should == :foo
    foo arg(1) name should == :bar
    foo arg(2) name should == :baz
    foo arg(0) = qux
    foo code should == "hello( qux mux,  bar man  , baz )"
  )

  it("arg= should replace last argument",
    foo = parse("hello( foo,  bar man  , baz )")
    qux = parse("qux mux")
    foo arg(0) name should == :foo
    foo arg(1) name should == :bar
    foo arg(2) name should == :baz
    foo arg(2) = qux
    foo code should == "hello( foo,  bar man  , qux mux)"
  )



)
    
