require File.expand_path("../../../spec_helper", __FILE__)
require 'akin/parser/message_reader'
require 'akin/parser/char_at'
require 'akin/parser/char_reader'
require 'akin/parser/position'

describe Akin::Parser::MessageReader do
  def read(type, code)
    if code.kind_of?(String)
      at = Akin::Parser::CharAt.from(Akin::Parser::CharReader.from_string(code),
                                     Akin::Parser::FilePosition.new(:eval))
    else
      at = code
    end
    Akin::Parser::MessageReader.new.send "read_#{type}", at
  end

  it "parses decimal integer" do
    o = read :decimal, "12345"
    o.type.should == :decimal
    o.data.should == "12345"
  end

  it "parses decimal integer with inner underscore" do
    o = read :decimal, "12_345"
    o.type.should == :decimal
    o.data.should == "12345"
  end

  it "parses binary integer" do
    o = read :decimal, "12345"
    o.type.should == :decimal
    o.data.should == "12345"
  end

  it "parses binary integer with 0b prefix" do
    o = read :binary, "0b10101"
    o.type.should == :binary
    o.data.should == "10101"
  end

  it "parses binary integer with 0B prefix" do
    o = read :binary, "0B10101"
    o.type.should == :binary
    o.data.should == "10101"
  end

  it "parses binary integer with inner underscore" do
    o = read :binary, "0b10_101"
    o.type.should == :binary
    o.data.should == "10101"
  end

  it "parses octal integer with 0o prefix" do
    o = read :octal, "0o7650"
    o.type.should == :octal
    o.data.should == "7650"
  end

  it "parses octal integer with 0O prefix" do
    o = read :octal, "0O7650"
    o.type.should == :octal
    o.data.should == "7650"
  end

  it "parses octal integer with 0 prefix" do
    o = read :octal, "07650"
    o.type.should == :octal
    o.data.should == "7650"
  end

  it "parses octal integer with inner underscore" do
    o = read :octal, "07_650"
    o.type.should == :octal
    o.data.should == "7650"
  end

  it "parses hexadecimal integer with 0x prefix" do
    o = read :hexadecimal, "0xCAFEBABE"
    o.type.should == :hexadecimal
    o.data.should == "CAFEBABE"
  end

  it "parses hexadecimal integer with 0X prefix" do
    o = read :hexadecimal, "0XCAFEBABE"
    o.type.should == :hexadecimal
    o.data.should == "CAFEBABE"
  end

  it "parses binary integer with inner underscore" do
    o = read :hexadecimal, "0xCAFE_BABE"
    o.type.should == :hexadecimal
    o.data.should == "CAFEBABE"
  end


end
