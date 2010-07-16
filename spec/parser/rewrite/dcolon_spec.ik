use("ispec")

use("akin")
use("akin/parser")

describe("Akin Parser", 

  parse = fn(txt, 
    tokens = Akin Tokenizer parseText(txt)
    Akin Parser Rewrite DColon rewrite(tokens))

  it("should append bwd message as argument to fwd",
    msg = parse("foo :: baz")
    msg code should == "baz(foo )"
  )

  it("should append bwd messages as argument to fwd",
    msg = parse("hello\n  foo, bar :: baz")
    msg code should == "hello\n  baz(foo, bar )"
  )

  it("should handle chained :: operators",
    msg = parse("foo, bar :: if(hello) :: if(bye)")
    msg code should == "if(bye,if(hello,foo, bar ) )"
  )


)

