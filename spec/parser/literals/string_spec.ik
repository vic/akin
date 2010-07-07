use("ispec")
use("akin")
use("akin/parser")

describe("Akin Parser parseText for text literals", 

  parse = fn(txt, Akin Parser parseText(txt))

  it("should parse simple text",
    msg = parse(#["hello"])
    msg name should be :("\"")
    msg should not be activation
    msg should be literal
    msg literal type should == :text
    msg literal parts first should == "hello"
  )

  it("should parse interpolating text",
    msg = parse(#["hel \#{lo wo} rld"])
    msg name should be :("\"")
    msg should not be activation
    msg should be literal
    msg literal type should == :text
    msg literal parts[0] should == "hel "
    msg literal parts[1] name should == :lo
    msg literal parts[1] next name should == :wo
    msg literal parts[1] next next should be nil
    msg literal parts[2] should == " rld"
  )

  it("should parse interpolating text with inner text",
    msg = parse(#["hel \#{lo "you" wo} rld"])
    msg name should be :("\"")
    msg should not be activation
    msg should be literal
    msg literal type should == :text
    msg literal parts[0] should == "hel "
    msg literal parts[1] name should == :lo
    msg literal parts[1] next name should == :("\"")
    msg literal parts[1] next should be literal
    msg literal parts[1] next literal type should == :text
    msg literal parts[1] next literal parts first should == "you"
    msg literal parts[1] next next name should  == :wo
    msg literal parts[2] should == " rld"
  )


)
