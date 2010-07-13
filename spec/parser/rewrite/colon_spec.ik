use("ispec")

use("akin")
use("akin/parser")

describe("Akin Parser", 

  parse = fn(txt, 
    tokens = Akin Tokenizer parseText(txt)
    Akin Parser Rewrite Colon rewrite(tokens))

  it("should do nothing if : takes parameters",
    msg = parse("hello :(bar) baz")
    msg code should == "hello :(bar) baz"
  )

  it("should do nothing if : starts a symbol",
    msg = parse("hello :bar baz")
    msg code should == "hello :bar baz"
  )

  it("should add following message as argument to preceding one",
    msg = parse("hello: bar")
    msg code should == "hello( bar)"
  )

  it("should append arguments to existing round body", 
    msg = parse("hello(foo): bar")
    msg code should == "hello(foo, bar)"
  )

  it("should append arguments to existing empty round body", 
    msg = parse("hello(): bar")
    msg code should == "hello( bar)"
  )

  it("should append arguments to existing curly body", 
    msg = parse("hello{foo}: bar")
    msg code should == "hello{foo, bar}"
  )

  it("should append arguments to existing empty curly body", 
    msg = parse("hello{}: bar")
    msg code should == "hello{ bar}"
  )

  it("should append arguments to existing square body", 
    msg = parse("hello[foo]: bar")
    msg code should == "hello[foo, bar]"
  )

  it("should append arguments to existing empty square body", 
    msg = parse("hello[]: bar")
    msg code should == "hello[ bar]"
  )

  it("should add two args until dot is found",
    msg = parse("hello: foo, bar. baz")
    msg code should == "hello( foo, bar.) baz"
  )

  it("should add two args until semicolon is found",
    msg = parse("hello: foo, bar; baz")
    msg code should == "hello( foo, bar;) baz"
  )

  it("should add arguments until colon is found at same column",
    msg = parse("hello: foo\n bar\n.")
    msg code should == "hello( foo\n bar\n.)"
  )

  it("should add arguments until colon is found at same column",
    msg = parse("hello: foo\n bar\n,\n baz\n bat\n. quxx")
    msg code should == "hello( foo\n bar\n,\n baz\n bat\n.) quxx"
  )

  it("should rewrite the message name",
    msg = parse("if: true,\n  hello\nelse:\n bye")
    msg code should == "if:else( true,\n  hello\n,\n bye)"
  )

  it("should rewrite the message name",
    msg = parse("foo if: true,\n      hello\n    else:\n      bye")
    msg code should == "foo if:else( true,\n      hello\n    ,\n      bye)"
  )

  it("should rewrite the message name until colon",
    msg = parse("if: true,\n  hello\nelse:\n bye; ux")
    msg code should == "if:else( true,\n  hello\n,\n bye;) ux"
  )

  it("should correctly rewrite inside arguments", 
    msg = parse("hello(foo: bar)")
    msg code should == "hello(foo( bar))"
  )

  it("should correctly rewrite nested statements", 
    msg = parse("foo: bar: baz. .bat")
    msg code should == "foo( bar( baz.) .)bat"
  )

  it("should not add comma if already have one",
    msg = parse("foo(bar, baz,): bat")
    msg code should == "foo(bar, baz, bat)"
  )

  it("should should not rewrite the message name if has parens", 
    {pending: true},
    msg = parse("case(n):\nmatch(a):\n hello\nis(b):\n bye")
    msg code should == "case(n,\nmatch(a),\n hello, is(b),\n bye)"
  )


)

