use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser parseText for comments", 

  parse = fn(txt, Akin Parser parseText(txt))

  it("should treat comments as whitespace, starting from #! to end of line",
    msg = parse("  #! A comment in akin\n is upto #! the end of line")
    msg should be space
    msg next should be terminator
    msg next next should be space
    msg next next next name should == :is
    msg next next next next name should == :upto
  )

  it("should treat c-like comments as literals",
    msg = parse("/* This is a comment */")
    msg should be literal
    msg literal parts first should == "This is a comment "
  )

  it("should allow code evaluateion",
    msg = parse("/***
      * \#{ foo }
      *
      * This is a \#{nice} comment
      * boy 
      * 
      * @author \#{ bla }
      **/")
    msg should be literal
    msg literal parts inspect println
  )



)
