use("ispec")

use("akin")
use("akin/parser")

describe("Akin Parser", 

  parse = fn(txt, 
    tokens = Akin Tokenizer parseText(txt)
    Akin Parser Rewrite DColon rewrite(tokens))

  it("should append previous message as argument to next",
    msg = parse("foo :: baz")
    msg code should == "baz(foo )"
  )

  it("should append previous messages as argument to next",
    msg = parse("hello\n  foo, bar :: baz")
    msg code should == "hello\n  baz(foo, bar )"
  )

  it("should handle chained :: operators",
    msg = parse("foo, bar :: if(hello) :: if(bye)")
    msg code should == "if(bye,if(hello,foo, bar ) )"
  )


)

