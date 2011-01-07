require File.expand_path("../../spec_helper", __FILE__)

describe Akin::Parser::Syntax do
  def parse(name, input)
    unless input.kind_of? Akin::Parser::MatchInput
      r = Akin::Parser::CharReader.from_string(input)
      f = Akin::Parser::FilePosition.new :eval, Akin::Parser::CharPosition.default
      input = Akin::Parser::MatchInput.new(r, f)
    end
    Akin::Parser::Language.syntax.a(name).match(input)
  end

  describe "eol" do
    it "matches a unix_eol" do
      parse(:eol, "\n").positive?.should be_true
    end

    it "matches a win_eol" do
      parse(:eol, "\r\n").positive?.should be_true
    end
  end # eol

  describe "binary integer" do
    it "matches a binary digit sequence starting with 0b" do
      m = parse(:integer, "0b10101")
      m.base.should == 2
    end

    it "matches a binary digit sequence starting with 0B" do
      m = parse(:integer, "0B10101")
      m.base.should == 2
    end

    it "returns the binary digits as text" do
      m = parse(:integer, "0b10101")
      m.text.should == "10101"
    end

    it "returns the binary digits without underscores as text" do
      m = parse(:integer, "0b10_101")
      m.text.should == "10101"
    end

    it "returns the binary value" do
      m = parse(:integer, "0B10_101")
      m.value.should == 21
    end
  end # binary integer

  describe "octal integer" do
    it "matches a octal digit sequence starting with 0o" do
      m = parse(:integer, "0o707")
      m.base.should == 8
    end

    it "matches a octal digit sequence starting with 0O" do
      m = parse(:integer, "0O707")
      m.base.should == 8
    end

    it "matches a octal digit sequence starting with 0" do
      m = parse(:integer, "0707")
      m.base.should == 8
    end

    it "returns the octal digits as text" do
      m = parse(:integer, "0o7007")
      m.text.should == "7007"
    end

    it "returns the octal digits without underscores as text" do
      m = parse(:integer, "0o7_007")
      m.text.should == "7007"
    end

    it "returns the octal value" do
      m = parse(:integer, "0o7007")
      m.value.should == 3591
    end

    it "returns the octal value for digits starting with 0" do
      m = parse(:integer, "07007")
      m.value.should == 3591
    end
  end # octal integer


  describe "hexadecimal integer" do
    it "matches a hex digit sequence starting with 0x" do
      m = parse(:integer, "0xCafe")
      m.base.should == 16
    end

    it "matches a hex digit sequence starting with 0X" do
      m = parse(:integer, "0Xbeef")
      m.base.should == 16
    end

    it "returns the hex digits as text" do
      m = parse(:integer, "0xBeeF")
      m.text.should == "BeeF"
    end

    it "returns the hex digits without underscores as text" do
      m = parse(:integer, "0xDEAD_beef")
      m.text.should == "DEADbeef"
    end

    it "returns the binary value" do
      m = parse(:integer, "0Xdead_beef")
      m.value.should == 3735928559
    end
  end
end
