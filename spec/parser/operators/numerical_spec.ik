use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser on message bodys", 

  parse = fn(txt, 
    tokens = Akin Tokenizer parseText(txt)
    Akin Parser parseMessage(tokens))
  

  it("should rewrite + message",
    msg = parse("1 + 2")
    msg code should == "1 +(2)"
  )

)
