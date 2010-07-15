use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer for regexp literals", 

  parse = fn(txt, Akin Tokenizer parseText(txt))

  it("should parse simple regexp enclosed between $/ and  /",
    msg = parse("$/hello/")
    msg text should be nil
    msg should not be call
    msg type should == :regexp
    msg literal[:parts] first should == "hello"
    msg literal[:left] should == "$/"
    msg literal[:right] should == "/"
  )

  it("should parse simple regexp enclosed between $/ and  / with flags",
    msg = parse("$/hello/umix")
    msg text should be nil
    msg should not be call
    msg type should == :regexp
    msg literal[:parts] first should == "hello"
    msg literal[:flags] should == "umix"
  )

  it("should parse simple regexp enclosed between $/ and  / with engine",
    msg = parse("$/hello/:re2")
    msg text should be nil
    msg should not be call
    msg type should == :regexp
    msg literal[:parts] first should == "hello"
    msg literal[:flags] should be nil
    msg literal[:engine] should == "re2"
  )



)
