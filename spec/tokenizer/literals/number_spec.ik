use("ispec")
use("akin")
use("akin/tokenizer")

describe("Akin Tokenizer parseText for numeric literals", 

  parse = fn(txt, Akin Tokenizer parseText(txt))

  it("should parse hexadecimal literal",
    msg = parse("0xCAFEBABE")
    msg should not be call
    msg type should == :hexNumber
    msg text should == "CAFEBABE"
  )

  it("should parse hexadecimal literal with underscore",
    msg = parse("0xCAFE_BABE")
    msg should not be call
    msg type should == :hexNumber
    msg text should == "CAFEBABE"
  )


  it("should parse octal literal",
    msg = parse("01234567")
    msg should not be call
    msg type should == :octNumber
    msg text should == "1234567"
  )

  it("should parse octal literal with underscore",
    msg = parse("01_234_567")
    msg should not be call
    msg type should == :octNumber
    msg text should == "1234567"
  )

  it("should parse binary literal",
    msg = parse("0b0110100001100101011011000110110001101111")
    msg should not be call
    msg type should == :binNumber
    msg text should == "0110100001100101011011000110110001101111"
  )

  it("should parse binary literal with underscore",
    msg = parse("0b01_101_000_01101_00_1")
    msg should not be call
    msg type should == :binNumber
    msg text should == "0110100001101001"
  )

  it("should parse decimal integer literal",
    msg = parse("24") 
     msg should not be call
    msg type should == :decNumber
    msg literal[:integer] should == "24"
  )

  it("should parse decimal integer literal with underscore",
    msg = parse("24_000_000") 
    msg text should be nil
    msg should not be call
    msg type should == :decNumber
    msg literal[:integer] should == "24000000"
  )
  
  it("should parse decimal integer literal with underscore",
    msg = parse("24_000_000") 
    msg text should be nil
    msg should not be call
    msg type should == :decNumber
    msg literal[:integer] should == "24000000"
  )

)
