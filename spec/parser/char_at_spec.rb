require File.expand_path("../../spec_helper", __FILE__)
require 'akin/parser/position'
require 'akin/parser/char_reader'
require 'akin/parser/char_at'

describe Akin::Parser::CharAt do

  def reader(str)
    Akin::Parser::CharAt.from(Akin::Parser::CharReader.from_string(str),
                              Akin::Parser::FilePosition.new(:eval))
  end

  it "identify bin_digit" do
    reader("0").at_bin_digit?.should be_true
  end

  it "should identify not being at bin_digit" do
    reader("2").tap do |reader|
      reader.at_bin_digit?.should_not be_true
      reader.at_dec_digit?.should be_true
    end
  end

  it "should reach eof at end of string" do
    reader("01").tap do |at|
      at.at_bin_digit?.should be_true
      at.next.at_bin_digit?.should be_true
      at.next.next.at_eof?.should be_true
    end
  end

  it "should identify windows eol" do
    reader("\r\n").tap do |reader|
      reader.at_eol?.should be_true
      reader.at_win_eol?.should be_true
      reader.at_unix_eol?.should_not be_true
    end
  end

  it "should identify unix eol" do
    reader("\n").tap do |reader|
      reader.at_eol?.should be_true
      reader.at_win_eol?.should_not be_true
      reader.at_unix_eol?.should be_true
    end
  end

  it "should identify escaped windows eol as space" do
    reader("\\\r\n").tap do |reader|
      reader.at_space?.should be_true
    end
  end

  it "should identify escaped unix eol as space" do
    reader("\\\n").tap do |reader|
      reader.at_space?.should be_true
    end
  end

  it "should advance position when reading next char" do
    reader("foo").tap do |reader|
      reader.position.logical.index.should == 1
      reader.next.position.logical.index.should == 2
    end
  end

  it "should advance position when reading next line" do
    reader("f\no").tap do |reader|
      reader.position.logical.index.should == 1
      reader.next.position.logical.index.should == 2
      reader.next.next.position.logical.index.should == 3
    end
  end

  it "should advance linenum when reading next line" do
    reader("f\no").tap do |reader|
      reader.position.logical.pos.should == [1, 1, 1]
      reader.next.position.logical.pos.should == [1, 2, 2]
      reader.next.next.position.logical.pos.should == [2, 1, 3]
    end
  end

  it "should advance linenum when reading windows next line" do
    reader("f\r\no").tap do |reader|
      reader.position.logical.line.should == 1
      reader.next.position.logical.line.should == 1
      reader.next.next.position.logical.line.should == 2
      reader.next.next.char.should == "o"
    end
  end

  it "should not advance linenum when reading escaped unix eol" do
    reader("f\\\no").tap do |reader|
      reader.char.should == "f"
      reader.position.logical.pos.should == [1, 1, 1]
      reader.next.position.logical.pos.should == [1, 2, 2]
      reader.next.next.char.should == "o"
      reader.next.next.position.logical.pos.should == [1, 3, 3]
    end
  end

  it "should not advance linenum when reading escaped windows eol" do
    reader("f\\\r\no").tap do |reader|
      reader.char.should == "f"
      reader.position.logical.pos.should == [1, 1, 1]
      reader.next.position.logical.pos.should == [1, 2, 2]
      reader.next.next.char.should == "o"
      reader.next.next.position.logical.pos.should == [1, 3, 3]
    end
  end

end
