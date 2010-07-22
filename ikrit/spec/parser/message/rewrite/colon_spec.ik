use("ispec")

use("akin")
use("akin/parser")

describe("Akin Parser", 

  parse = fn(txt, Akin Parser parseText(txt))

  it("should do nothing if : takes parameters",
    msg = parse("hello :(bar) baz")
    msg code should == "hello :(bar) baz"
  )

  it("should do nothing if : starts a symbol",
    msg = parse("hello :bar baz")
    msg code should == "hello :bar baz"
  )


  it("",
    msg = parse("foo: hello")
    msg code should == "foo(hello)"
  )

  it("",
    msg = parse("a b: c. d")
    msg code should == "a b(c). d"
  )

  it("",
    msg = parse("a b: c; d")
    msg code should == "a b(c) d"
  )

  it("",
    msg = parse("a b:\n   c   \n  d")
    msg code should == "a b(c)\n  d"
  )

  it("should add following message as argument to bwdeding one",
    msg = parse("hello: bar")
    msg code should == "hello(bar)"
  )

  it("should append arguments to existing round body", 
    msg = parse("hello(foo): bar")
    msg code should == "hello(foo,bar)"
  )

  it("should append arguments to existing empty round body", 
    msg = parse("hello(): bar")
    msg code should == "hello(bar)"
  )

  it("should append arguments to existing curly body", 
    msg = parse("hello{foo}: bar")
    msg code should == "hello{foo,bar}"
  )

  it("should append arguments to existing empty curly body", 
    msg = parse("hello{}: bar")
    msg code should == "hello{bar}"
  )

  it("should append arguments to existing square body", 
    msg = parse("hello[foo]: bar")
    msg code should == "hello[foo,bar]"
  )

  it("should append arguments to existing empty square body", 
    msg = parse("hello[]: bar")
    msg code should == "hello[bar]"
  )

  it("should add two args until dot is found",
    msg = parse("hello: foo, bar. baz")
    msg code should == "hello(foo, bar). baz"
  )

  it("should add two args until semicolon is found",
    msg = parse("hello: foo, bar; baz")
    msg code should == "hello(foo, bar) baz"
  )

  it("should add arguments until colon is found at same column",
    msg = parse("hello: foo\n bar\n.")
    msg code should == "hello(foo\n bar)."
  )

  it("should add arguments until colon is found at same column",
    msg = parse("a b: c\n   d\n   ,e\n   f\n  . quxx")
    msg code should == "a b(c\n   d\n   ,e\n   f). quxx"
  )

  it("should rewrite the message name",
    msg = parse("
foo
  if: true,
    hello
  else:
    bye
bar
")
    msg code should == "
foo
  if:else(true,
    hello
  ,
    bye)
bar
"
  )


  it("should rewrite the message name",
    msg = parse("
foo
  if: true,
    hello
  else:
    bye
  .
bar
")
    msg code should == "
foo
  if:else(true,
    hello
  ,
    bye).
bar
"
  )

  it("should rewrite the message name",
    msg = parse("
foo
  if: true,
    hello
  else:
    bye
  ; baz
bar
")
    msg code should == "
foo
  if:else(true,
    hello
  ,
    bye) baz
bar
"
  )


  it("should rewrite the message name",
    msg = parse("
if: true,
  hello
else:
  bye
")
    msg code should == "
if:else(true,
  hello
,
  bye)
"
  )


  it("should rewrite the message name",
    msg = parse("
foo if: true,
      hello
    else:
      bye
bar")
    msg code should == "
foo if:else(true,
      hello
    ,
      bye)
bar"
  )

  it("should rewrite the message name until colon",
    msg = parse("
if: true,
  hello
else:
  bye
; ux")
    msg code should == "
if:else(true,
  hello
,
  bye) ux"
  )

  it("should correctly rewrite inside arguments", 
    msg = parse("hello(foo: bar)")
    msg code should == "hello(foo(bar))"
  )

  it("should correctly rewrite inside arguments", 
    msg = parse("hello: foo: bar")
    msg code should == "hello(foo(bar))"
  )

  it("should correctly rewrite nested statements", 
    msg = parse("foo: bar: baz. bat")
    msg code should == "foo(bar(baz)). bat"
  )

  it("should correctly rewrite nested semicolon statements", 
    msg = parse("foo: bar: baz; bat; man")
    msg code should == "foo(bar(baz) bat) man"
  )


  it("should not add comma if already have one",
    msg = parse("foo(bar, baz,): bat")
    msg code should == "foo(bar, baz,bat)"
  )

  it("should should not rewrite the message name if has parens", 
    msg = parse("
case(n):
match(a): hello
is(b): bye")
    msg code should == "
case(n,match(a), hello\n,is(b), bye)"
  )


  it("should should not rewrite names already seen", 
    msg = parse("
bla(n):
foo: hello
foo: bye")
    msg code should == "
bla:foo(n, hello\n, bye)"
  )

  it("should should not rewrite names already seen", 
    msg = parse("
foo bar:
  baz: bat
")
    msg code should == "
foo bar(baz(bat)
)
"
  )

  it("should", 
    msg = parse("
foo bar baz: 
  a
  b
")
    msg code should == "
foo bar baz(a
  b
)
"
  )

  it("should", 
    msg = parse("
foo bar baz: 
  a
  bat:
  man
")
    msg code should == "
foo bar baz(a
  bat(man
)
)
"
  )

  it("should", 
    msg = parse("
foo bar baz: 
  a
        bat:
  man
")
    msg code should == "
foo bar baz(a
        bat(man
)
)
"
  )

  it("should", 
    msg = parse("
foo bar baz: 
  a
bat:
  man
")
    msg code should == "
foo bar baz(a
bat(man)
)
"
  )


  it("should", 
    msg = parse("
    a = b: c
")
    msg code should == "
    =(a,b(c))
"
  )

  it("should", 
    msg = parse("
    a = : b
")
    msg code should == "
    a =(b)
"
  )

  it("should", 
    msg = parse("a =: b")
    msg code should == "=(a,(b))"
    msg arg(0) text should == "a"
    msg arg(1) text should be nil
    msg arg(1) type should == :code
    msg arg(1) literal should be nil
  )

  it("should", 
    msg = parse("
    a = (n, m): n + m
")
    msg code should == "
    =(a,(n, m,n +(m)))
"
  )

  it("should", 
    msg = parse("
    a = (): n, m, n + m
")
    msg code should == "
    =(a,(n, m, n +(m)))
"
  )

  it("should",
    msg = parse("a(): b")
    msg code should == "a(b)"
    msg text should == "a"
    msg literal should be nil
  )

  it("should",
    msg = parse("(): b")
    msg code should == "(b)"
    msg text should be nil
    msg type should == :code
  )

  it("should",
    msg = parse("{}: b")
    msg code should == "{b}"
    msg text should be nil
    msg type should == :code
    msg literal should be nil
  )

  it("should",
    msg = parse("[]: b")
    msg code should == "[b]"
    msg text should be nil
    msg type should == :code
    msg literal should be nil
  )

)

