use("ispec")

use("akin")
use("akin/parser")

describe("Akin Parser Rewrite Semicolon", 

  parse = fn(txt, Akin Parser parseText(txt))

  it("should replace semicolon with space",
    msg = parse("foo;bar")
    msg code should == "foo bar"
  )

  it("should detach semicolon when having space at left",
    msg = parse("foo ;bar")
    msg code should == "foo bar"
  )

  it("should detach semicolon when having space at right",
    msg = parse("foo; bar")
    msg code should == "foo bar"
  )

  it("should leave single space when having space at both sides",
    msg = parse("foo ; bar")
    msg code should == "foo bar"
  )
  
  it("should leave single space joining lines",
    msg = parse("foo \n;\n bar")
    msg code should == "foo bar"
  )

  it("should replace several ; by single space",
    msg = parse("foo;;;;bar")
    msg code should == "foo bar"
  )

  it("should add space at end without space at sides",
    msg = parse("foo;")    msg code should == "foo "
  )
)
