use("ispec")

use("akin")
use("akin/parser")

describe("Akin Parser", 

  parse = fn(txt, Akin Parser parseText(txt))

  it("should append bwd message as argument to fwd",
    msg = parse("jaja\n   foo :: baz   ")
    msg code should == "jaja\n   baz(foo)   "
  )


  it("should append bwd message as argument to fwd",
    msg = parse("foo :: baz")
    msg code should == "baz(foo)"
  )

  it("should append bwd messages as argument to fwd",
    msg = parse("hello\n  foo, bar :: baz")
    msg code should == "hello\n  baz(foo, bar)"
  )

  it("should handle chained :: operators",
    msg = parse("foo, bar :: if(hello) :: if(bye)")
    msg code should == "if(bye,if(hello,foo, bar))"
  )


)

