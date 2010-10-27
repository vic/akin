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

  it("should default to round braces for empty message",
    msg = parse("  : a, b, c ")
    msg code should == "  ( a, b, c )"
  )

  it("should default to round braces for empty message",
    msg = parse("  :;")
    msg code should == "  () "
  )

  it("should default to round braces for empty message",
    msg = parse("  :.")
    msg code should == "  ()."
  )

  it("should create block literal for empty message",
    msg = parse("  ():.")
    msg code should == "  \\()."
  )

  it("should default to round braces for \\ message",
    msg = parse("  \\: a, b, c ")
    msg code should == "  \\( a, b, c )"
  )

  it("should create a block literal for empty round message",
    msg = parse("  (): a, b, c ")
    msg code should == "  \\( a, b, c )"
  )

  it("should create a block literal for empty square message",
    msg = parse("  []: a, b, c ")
    msg code should == "  \\[ a, b, c ]"
  )

  it("should create a block literal for empty curly message",
    msg = parse("  {}: a, b, c ")
    msg code should == "  \\{ a, b, c }"
  )

  it("should create a block literal for round activation",
    msg = parse("  (a,b): a b ")
    msg code should == "  \\(a,b, a b )"
  )

  it("should create a block literal for square activation",
    msg = parse("  [a,b]: a b ")
    msg code should == "  \\[a,b, a b ]"
  )

  it("should create a block literal for curly activation",
    msg = parse("  {a,b}: a b ")
    msg code should == "  \\{a,b, a b }"
  )

  it("should create a block literal for activation on assignment rhs",
    msg = parse("add = (a,b): a + b")
    msg code should == "=(add,\\(a,b, a +(b)))"
  )

  it("should add single argument after colon",
    msg = parse("hello: world")
    msg code should == "hello( world)"
  )

  it("should add arguments until same line dot",
    msg = parse("hello: world.bye")
    msg code should == "hello( world).bye"
  )

  it("should add arguments until same line semicolon",
    msg = parse("hello: world;bye")
    msg code should == "hello( world) bye"
  )

  it("should append argument to empty body",
    msg = parse("hello(): world")
    msg code should == "hello( world)"
  )

  it("should append argument to body with args, adding a comma",
    msg = parse("hello(akin): world")
    msg code should == "hello(akin, world)"
  )

  it("should add arguments that are on indented new line",
    msg = parse("hello:\n world")
    msg code should == "hello(\n world)"
  )

  it("should add arguments until message on same indent level",
    msg = parse("hello: akin\nworld")
    msg code should == "hello( akin)\nworld"
  )

  it("should add arguments until message on same indent level",
    msg = parse("hello: akin\nworld\nbye")
    msg code should == "hello( akin)\nworld\nbye"
  )

  it("should add arguments until unindented message at less level",
    msg = parse("  hello: akin\nworld")
    msg code should == "  hello( akin)\nworld"
  )

  it("should add comma after argument on same line",
    msg = parse("  if: hello\n   world")
    msg code should == "  if( hello,\n   world)"
  )

  it("should add comma after argument on same line before spaces",
    msg = parse("  if: hello    \n   world")
    msg code should == "  if( hello,    \n   world)"
  )

  it("should not add comma after argument on same line if there is one",
    msg = parse("  if: hello,\n   world")
    msg code should == "  if( hello,\n   world)"
  )

  it("should not add comma after argument on same line if there is one even with spaces",
    msg = parse("  if: hello  , \n   world")
    msg code should == "  if( hello  , \n   world)"
  )

  
  it("should parse an smalltalk like message",
    msg = parse("Point x: 22 y: 33")
    msg code should == "Point x:y( 22 , 33)"
  )

  it("should parse an smalltalk like message with comma",
    msg = parse("Point x: 22, y: 33 z: 11")
    msg code should == "Point x:y:z( 22,  33 , 11)"
  )

  it("should parse an smalltalk like conditional with explicit braces",
    msg = parse(" (a < b) then: b else: a ")
    msg code should == " (a <(b)) then:else( b , a )"
  )

  it("should parse an smalltalk like conditional using semicolon",
    msg = parse(" a < b; then: b else: a ")
    msg code should == " a <(b) then:else( b , a )"
  )

  it("should not continue message after semicolon found on same line",
    msg = parse("hello: world; here: i am")
    msg code should == "hello( world) here( i am)"
  )

  it("should add arguments to operator",
    msg = parse("my =: age, 27")
    msg code should == "my =( age, 27)"
  )

  it("should add semicolon to name if body continues with empty semicolon",
    msg = parse("foo bar: baz : qux")
    msg code should == "foo bar:( baz, qux)"
  )

  it("should be possible to emulate a c-style ternary if operator ?: ",
    msg = parse("foo ?: baz : qux")
    msg code should == "foo ?:( baz, qux)"
  )

  it("should be possible to emulate a c-style ternary if operator ?: ",
    msg = parse("foo ?:(baz,qux)")
    msg code should == "foo ?:(baz,qux)"
  )

  it("should allow nested message in same line",
    msg = parse("foo bar: baz: qux")
    msg code should == "foo bar( baz( qux))"
  )

  it("should parse an indented if/else",
    src = "
      if: uno
        dos
      else:
        tres
      "
    msg = parse(src)
    msg code should == "
      if:else(uno,
        dos,
        tres
      )"
  )

  it("should parse an indented if/elsif/else",
    src = "
      if: uno
        one
      elsif: dos
        two
      else:
        three
      "
    msg = parse(src)
    src println
    msg code println
    msg code should == "
      if:elsif:else(uno,
        one,
        dos,
        two,
        three
      )"
  )

  it("should not add arguments after uindented message",
    msg = parse("a:\n b\nc\nd:\n e")
    msg code should == "a(\n b)\nc\nd(\n e)"
  )

  it("should not add arguments after uindented message",
    msg = parse("a:\n b\nc d: e")
    msg code should == "a(\n b)\nc d(e)"
  )

  it("should parse a nested if/else",
    msg = parse("
      if: uno
        one
      else: if: dos
        two
      else:
        three
      ")
    msg code should == "
      if:else(uno,
        one,
        if:else(dos,
        two,
        three
      ))"
  )

  it("should end a nested if/else when unindented message found",
    src = "
      if: uno
        one
      else: if: dos
        two
      else:
        three
      four
      "
    msg = parse(src)
    src println
    msg code println
    msg code should == "
      if:else(uno,
        one,
        if:else(dos,
        two,
        three))
      four
      "
  )

  it("should end a deep nested if/else when unindented message found",
    src = "
      if: uno
        one
      else: if: dos
        two
      else: if: tres
        three
      else:
        four
      "

    msg = parse(src)
    msg code should == "
      if:else(uno,
        one,
        if:else(dos,
        two,
        three))
      four
      "
  )

)
