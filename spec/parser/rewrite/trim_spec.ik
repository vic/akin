use("ispec")

use("akin")
use("akin/parser")

describe("Akin Parser", 

  parse = fn(txt, 
    tokens = Akin Tokenizer parseText(txt)
    Akin Parser Rewrite Trim rewrite(tokens))

  it("should remove spaces and terminators at both ends",
    msg = parse(". \n . foo bar . \n .")
    msg code should == "foo bar"
  )

)

