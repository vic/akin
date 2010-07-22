use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser", 

  parse = fn(txt, Akin Parser parseText(txt))

  it("should not alter chain without operators",
    msg = parse("foo bar baz")
    msg code should == "foo bar baz"
  )

  it("should rewrite binary plus",
    msg = parse("hello + bar")
    msg code should == "hello +(bar)"
  )

  it("should rewrite binary plus",
    msg = parse("hello + bar bat . man")
    msg code should == "hello +(bar bat) . man"
  )

  it("should rewrite binary plus",
    msg = parse("foo + bar + baz")
    msg code should == "foo +(bar) +(baz)"
  )

  it("should rewrite binary mult",
    msg = parse("a * b + c")
    msg code should == "a *(b) +(c)"
  )

  it("should rewrite binary mult",
    msg = parse("a + b * c")
    msg code should == "a +(b *(c))"
  )

  it("should rewrite binary mult",
    msg = parse("a + b e f * c g h")
    msg code should == "a +(b e f *(c g h))"
  )

  it("should rewrite binary mult",
    msg = parse("a + b * c . d + e")
    msg code should == "a +(b *(c)) . d +(e)"
  )

  it("should rewrite binary op",
    msg = parse("a + b * c - d")
    msg code should == "a +(b *(c)) -(d)"
  )

  it("should rewrite inside arguments",
    msg = parse("a + foo(b * c) - d")
    msg code should == "a +(foo(b *(c))) -(d)"
  )

  it("should not rewrite if operator has arguments",
    msg = parse("a -(b)")
    msg code should = "a -(b)"
  )

  it("should rewrite left associative",
    msg = parse("a - b - c")
    msg code should == "a -(b) -(c)"
  )

  it("should rewrite right associative",
    msg = parse("a ** b ** c")
    msg code should == "a **(b **(c))"
  )

  it("should rewrite right associative",
    msg = parse("a ! b + c ! d")
    msg code should == "a !(b) +(c !(d))"
  )

  it("should allow new lines after operator",
    msg = parse("a + \n b")
    msg code should == "a +(b)"
  )

  it("should allow several new lines or comments after operator",
    msg = parse("a + \n # A comment here! \n b")
    msg code should == "a +(b)"
  )

  it("should rewrite assignmet",
    msg = parse("a = b")
    msg code should == "=(a,b)"
  )

  it("should rewrite assignment",
    msg = parse("a = b c d")
    msg code should == "=(a,b c d)"
  )

  it("should rewrite assignment",
    msg = parse("a = b c d\n")
    msg code should == "=(a,b c d)\n"
  )

  it("should correctly rewrite assignment precedence",
    msg = parse("a + b = c + d")
    msg code should == "a +(=(b,c +(d)))"
  )

  it("should rewrite unary minusminus",
    msg = parse("a -- b")
    msg code should == "--(a) b"
  )

  it("should rewrite unary plusplus",
    msg = parse("foo a ++ b")
    msg code should == "foo ++(a) b"
  )

)

