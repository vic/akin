use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer parseText for text literals", 

  parse = fn(txt, Akin Tokenizer parseText(txt))

  it("should parse simple text",
    msg = parse(#["hello"])
    msg name should be nil
    msg should not be body
    msg should be literal
    msg literal type should == :text
    msg literal parts first should == "hello"
  )

  it("should parse interpolating text",
    msg = parse(#["hel \#{lo wo} rld"])
    msg name should be nil
    msg should not be body
    msg should be literal
    msg literal type should == :text
    msg literal parts[0] should == "hel "
    msg literal parts[1] name should == :lo
    msg literal parts[1] next name should == :("")
    msg literal parts[1] next next name should == :wo
    msg literal parts[1] next next next should be nil
    msg literal parts[2] should == " rld"
  )

  it("should parse interpolating text with inner text",
    msg = parse(#["hel \#{lo "you" wo} rld"])
    msg name should be nil
    msg should not be body
    msg should be literal
    msg literal type should == :text
    msg literal parts[0] should == "hel "
    msg literal parts[1] name should == :lo
    msg literal parts[1] next name should == :("")
    msg literal parts[1] next next name should be nil
    msg literal parts[1] next next should be literal
    msg literal parts[1] next next literal type should == :text
    msg literal parts[1] next next literal parts first should == "you"
    msg literal parts[1] next next next name should  == :("")
    msg literal parts[1] next next next next name should  == :wo
    msg literal parts[2] should == " rld"
  )

  it("should parse simple text enclosed between $[ and  ]",
    msg = parse("$[hello]")
    msg name should be nil
    msg should not be body
    msg should be literal
    msg literal type should == :text
    msg literal parts first should == "hello"
  )

)
