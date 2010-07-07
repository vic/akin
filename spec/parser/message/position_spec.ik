use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser parseText sets message position", 

  parse = fn(txt, file :foo, ln 1, co 1, pos 1,
    Akin Parser parseText(txt, filename: file, line: ln, col: co, pos: pos))

  it("should produce Messages with position data",
    msg = parse("hello")
    msg position asList should == [:foo, 1, 1, 1]
  )

  it("should track position as data is read", {pending: true},
    msg = parse("  \n  \n  hello")
    msg position asList should == [:foo, 3, 3, 9]
  )

  

)
