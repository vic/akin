use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer parseText for text literals", 

  parse = fn(txt, Akin Tokenizer parseText(txt))

  it("should parse simple text",
    msg = parse(#["hello"])
    msg text should be nil
    msg should not be call
    msg type should == :text
    msg literal[:parts] first should == "hello"
  )

  it("should parse interpolating text",
    msg = parse(#["hel $(lo wo) rld"])
    msg text should be nil
    msg should not be call
    msg type should == :text
    msg literal[:parts][0] should == "hel "
    msg literal[:parts][1] text should == "lo"
    msg literal[:parts][1] succ text should == " "
    msg literal[:parts][1] succ succ text should == "wo"
    msg literal[:parts][1] succ succ succ should be nil
    msg literal[:parts][2] should == " rld"
  )

  it("should parse interpolating text with inner text",
    msg = parse(#["hel $(lo "you" wo) rld"])
    msg text should be nil
    msg should not be call
    msg type should == :text
    msg literal[:parts][0] should == "hel "
    msg literal[:parts][1] text should == "lo"
    msg literal[:parts][1] succ text should == " "
    msg literal[:parts][1] succ succ text should be nil
    msg literal[:parts][1] succ succ type should == :text
    msg literal[:parts][1] succ succ literal[:parts] first should == "you"
    msg literal[:parts][1] succ succ succ text should  == " "
    msg literal[:parts][1] succ succ succ succ text should  == "wo"
    msg literal[:parts][2] should == " rld"
  )

  it("should parse simple text enclosed between $[ and  ]",
    msg = parse("$[hello]")
    msg text should be nil
    msg should not be call
    msg type should == :text
    msg literal[:parts] first should == "hello"
  )

)
