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

  it("should treat documentation starting with /* as docs for developers",
    msg = parse("/* This is a comment */")
    msg should be literal
    msg literal text should == "/* This is a comment */"
    msg literal type should == :doc4dev
  )

  it("should treat documentation starting with /** as docs for api users",
    msg = parse("/** This is a comment */")
    msg should be literal
    msg literal text should == "/** This is a comment */"
    msg literal type should == :doc4api
  )

  it("should treat documentation starting with /*** as docs for app users",
    msg = parse("/*** This is a comment */")
    msg should be literal
    msg literal text should == "/*** This is a comment */"
    msg literal type should == :doc4usr
  )

)
